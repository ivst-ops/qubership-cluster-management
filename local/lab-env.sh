#!/usr/bin/env bash
# Local lab environments on one Docker host (a VM, WSL 2, a CI runner), called by Taskfile.yml on the host.
# Each checkout (a worktree, a parallel session) leases its own numbered slot, so labs started from several checkouts
# at once never share a Compose project, a host port, a Docker network or a customer environment name.
#
# The lease is the slot's Docker network: a network name exists once per Docker host, so `docker network create`
# is the atomic step, and its labels qcm.lab.slot and qcm.lab.owner (the checkout path) say whose it is. The checkout
# keeps its slot in .local-runtime/lab.env, which Compose reads (--env-file) and the tools container gets as its
# environment. This file is the only place the slot's names and ports are defined.
#
# Slot 0 has the slot-0 layout: projects atmos-local and atmos-local-azure, network aws-local_default,
# environment names without a suffix and ports 4566, 80, 4500, 4577... The first checkout on a host gets it, and so
# does the checkout whose Compose containers use an existing unlabelled aws-local_default; a slot whose subnet is taken
# (a VPN, kind) is skipped, so LAB_NET_PREFIX, not the order of checkouts, decides who keeps slot 0. Slot N
# (1..QCM_LAB_MAX_SLOT, default and maximum 9: the ports end below slot 0's EC2 range 30000+):
#   projects qcm-lab-N, qcm-lab-N-azure; network qcm-lab-N (10.99.N.0/24); environment names <name>-sN;
#   host ports in 20000+1000*N .. +999.
# Usage: local/lab-env.sh acquire | check | show | list | stop-all | release
set -euo pipefail
cd "$(dirname "$0")/.."

ROOT=$PWD FILE=.local-runtime/lab.env LEGACY=aws-local_default
MAX=${QCM_LAB_MAX_SLOT:-9}
[[ $MAX =~ ^[0-9]+$ ]] && ((MAX <= 9)) || { echo "QCM_LAB_MAX_SLOT must be 0..9, not $MAX." >&2; exit 1; }
LAB_PROJECTS='^(atmos-local(-azure)?|qcm-lab-[0-9]+(-azure)?|qcm-registry-cache)$'

die() { echo "$*" >&2; exit 1; }
network_of() { if (($1 == 0)); then echo "$LEGACY"; else echo "qcm-lab-$1"; fi; }
project_of() { if (($1 == 0)); then echo atmos-local; else echo "qcm-lab-$1"; fi; }
label_of() { docker network inspect -f "{{with index .Labels \"$2\"}}{{.}}{{end}}" "$1" 2>/dev/null; }
saved_slot() { sed -n 's/^QCM_LAB_SLOT=\([0-9][0-9]*\)$/\1/p' "$FILE" 2>/dev/null || true; }

# Whether this checkout owns the slot's network: by label, or for an unlabelled aws-local_default (a slot-0 lab created
# without lab-env.sh) by the Compose working directory of its floci container.
owns() {
    local net; net=$(network_of "$1")
    [[ $(label_of "$net" qcm.lab.owner) == "$ROOT" ]] && return 0
    (($1 == 0)) && [[ -z $(label_of "$net" qcm.lab.owner) ]] &&
        docker ps -a --filter "network=$LEGACY" --filter label=com.docker.compose.service=floci \
            --format '{{.Label "com.docker.compose.project.working_dir"}}' |
        grep -qxF "$ROOT/local"
}

# Takes slot N for this checkout or confirms it is ours; fails when another checkout has it or its subnet is taken.
claim() {
    local net subnet err; net=$(network_of "$1")
    if docker network inspect "$net" >/dev/null 2>&1; then owns "$1"; return; fi
    if (($1 == 0)); then subnet=${QCM_LAB_NET_PREFIX:-172.18}.0; else subnet=10.99.$1; fi
    err=$(docker network create --subnet "$subnet.0/$( (($1 == 0)) && echo 16 || echo 24)" --gateway "$subnet.1" \
        --label "qcm.lab.slot=$1" --label "qcm.lab.owner=$ROOT" "$net" 2>&1 >/dev/null) && return 0
    # Another checkout created it a moment ago: the slot is taken (or ours, if that was an earlier attempt of ours).
    [[ $err == *"already exists"* ]] && { owns "$1"; return; }
    # The subnet is used by another network (a VPN, kind...): say so and let acquire try the next slot.
    [[ $err == *[Pp]ool*overlap* ]] && { echo "Slot $1 skipped: subnet $subnet.0 is in use ($err)." >&2; return 1; }
    die "Cannot create the lab network $net: $err"
}

# Group id of the Docker socket as the containers see it (on Docker Desktop that is the VM, not the host file).
# The alpine image is ALPINE_IMAGE of Taskfile.yml (same digest as local/lab/Dockerfile).
docker_gid() {
    docker run --rm --pull=never -v /var/run/docker.sock:/var/run/docker.sock \
        alpine:3.22@sha256:49340b346798875b5592e5d420241f2f9cfba5f47e62ebb1446a1b34734e898f stat -c %g /var/run/docker.sock 2>/dev/null ||
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            alpine:3.22@sha256:49340b346798875b5592e5d420241f2f9cfba5f47e62ebb1446a1b34734e898f stat -c %g /var/run/docker.sock
}

write_env() {
    local slot=$1 net base sfx aws ui alb api az azapi eks aks ssh app b
    net=$(network_of "$slot")
    # The first three octets come from the network itself: a slot-0 network may predate QCM_LAB_NET_PREFIX.
    base=$(docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}' "$net")
    [[ $base =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.0/ ]] || die "Unexpected subnet '$base' of network $net."
    base=${BASH_REMATCH[1]}
    if ((slot == 0)); then
        sfx= aws=4566 ui=4500 alb=80 api=4590 az=4577 azapi=4591 eks=6500 aks=6600 ssh=2200 app=30000
    else
        b=$((20000 + 1000 * slot)) sfx=-s$slot
        aws=$((b + 566)) ui=$((b + 500)) alb=$((b + 80)) api=$((b + 590)) az=$((b + 577)) azapi=$((b + 591))
        eks=$((b + 600)) aks=$((b + 700)) ssh=$((b + 200)) app=$((b + 800))
    fi
    mkdir -p .local-runtime
    cat >"$FILE.tmp" <<EOF
# Lab environment of this checkout, written by local/lab-env.sh acquire; read by Compose (--env-file).
QCM_LAB_SLOT=$slot
QCM_LAB_SUFFIX=$sfx
QCM_LAB_PROJECT=$(project_of "$slot")
QCM_LAB_AZURE_PROJECT=$(project_of "$slot")-azure
QCM_LAB_NETWORK=$net
QCM_LAB_FLOCI_IP=$base.2
QCM_LAB_UI_IP=$base.3
QCM_LAB_AWS_PORT=$aws
QCM_LAB_UI_PORT=$ui
QCM_LAB_ALB_PORT=$alb
QCM_LAB_API_PORT=$api
QCM_LAB_AZURE_PORT=$az
QCM_LAB_AZURE_API_PORT=$azapi
QCM_LAB_EKS_PORT_MIN=$eks
QCM_LAB_EKS_PORT_MAX=$((eks + 99))
QCM_LAB_AKS_PORT_MIN=$aks
QCM_LAB_AKS_PORT_MAX=$((aks + 99))
QCM_LAB_SSH_PORT_MIN=$ssh
QCM_LAB_SSH_PORT_MAX=$((ssh + 99))
QCM_LAB_APP_PORT_MIN=$app
QCM_LAB_APP_PORT_MAX=$((app + $( ((slot == 0)) && echo 999 || echo 199)))
QCM_LAB_NAMESPACE=${sfx#-}
# The lab sidecar runs as this user (reads the 0600 token) with the group of the Docker socket.
QCM_LAB_UID=$(id -u)
QCM_LAB_GID=$(id -g)
QCM_LAB_DOCKER_GID=$(docker_gid)
EOF
    mv "$FILE.tmp" "$FILE"
}

cmd_acquire() {
    local slot; slot=$(saved_slot)
    if [[ -n $slot ]]; then
        # A checkout keeps its slot: its OpenTofu state and Floci data refer to the names of that slot.
        claim "$slot" || die "Lab environment $slot of this checkout ($(network_of "$slot")) belongs to" \
            "$(label_of "$(network_of "$slot")" qcm.lab.owner) now. Destroy what this checkout deployed," \
            "remove $FILE and run task lab:up again for a new one."
    else
        for ((slot = 0; slot <= MAX; slot++)); do claim "$slot" && break; done
        ((slot <= MAX)) || die "All lab environments 0..$MAX of this Docker host are taken (task lab:list):" \
            "release one (task lab:release in its checkout)."
    fi
    write_env "$slot"
    echo "Lab environment $slot ($(network_of "$slot")) for $ROOT; settings in $FILE." >&2
}

cmd_list() {
    local net slot owner running
    printf '%-5s %-18s %-8s %s\n' SLOT NETWORK RUNNING OWNER
    for net in $(docker network ls --format '{{.Name}}' | grep -E "^($LEGACY|qcm-lab-[0-9]+)$" | sort -V); do
        slot=${net#qcm-lab-} owner=$(label_of "$net" qcm.lab.owner)
        [[ $net == "$LEGACY" ]] && slot=0
        running=$(docker ps -q --filter "label=com.docker.compose.project=$(project_of "$slot")" | grep -c . || true)
        running=$((running + $(docker ps -q --filter "label=com.docker.compose.project=$(project_of "$slot")-azure" | grep -c . || true)))
        if [[ -z $owner ]]; then owner='(slot-0 lab, no owner label)'; elif [[ ! -d $owner ]]; then owner+=' (checkout removed)'; fi
        printf '%-5s %-18s %-8s %s\n' "$slot" "$net" "$running" "$owner"
    done
    echo "Image cache qcm-registry-cache (all slots): $(docker inspect -f '{{.State.Status}}' qcm-registry-cache 2>/dev/null || echo 'not created')"
}

# Stops every lab on this Docker host: the Compose services of all lab projects and the shared image cache, then the
# containers Floci started for them (k3s nodes, EC2 instances, port forwards, registries: label io.floci, or names
# floci-* of older Floci).
# Data, volumes and networks are kept; task lab:up starts a lab again, and prepare restarts its stopped nodes.
cmd_stop_all() {
    local p ids any=
    for p in $(docker ps --format '{{.Label "com.docker.compose.project"}}' | grep -E "$LAB_PROJECTS" | sort -u); do
        echo "Stopping lab $p"
        # shellcheck disable=SC2046
        docker stop -t 30 $(docker ps -q --filter "label=com.docker.compose.project=$p") >/dev/null; any=1
    done
    ids=$({ docker ps -q --filter label=io.floci; docker ps -q --filter 'name=^floci-'; } | sort -u)
    if [[ -n $ids ]]; then
        echo "Stopping $(grep -c . <<<"$ids") Floci containers (k3s nodes, EC2 instances, forwards, registries)"
        # shellcheck disable=SC2086
        docker stop -t 30 $ids >/dev/null; any=1
    fi
    [[ -n $any ]] || echo 'No running lab on this Docker host.'
}

# Fails unless lab.env names a slot this checkout holds (or whose network is gone): every task that acts on the lab of
# this checkout runs it first, so a stale lab.env never stops or removes the lab of another checkout.
cmd_check() {
    local slot; slot=$(saved_slot)
    [[ -n $slot ]] || die "This checkout has no lab environment yet ($FILE): run task lab:up first."
    ! docker network inspect "$(network_of "$slot")" >/dev/null 2>&1 || owns "$slot" ||
        die "Lab environment $slot ($(network_of "$slot")) belongs to $(label_of "$(network_of "$slot")" qcm.lab.owner) now," \
            "not to this checkout: remove $FILE and run task lab:up for a new one."
}

# Removes the lab of this checkout and gives the slot back: the Compose services (after the shared image cache is
# detached from their networks), what Floci started and outlived Compose (the ECR registry...), the network lease and
# lab.env. Only for a slot this checkout holds; a stale lab.env of a slot another checkout holds is just removed.
cmd_release() {
    local slot net n ids f; slot=$(saved_slot)
    [[ -n $slot ]] || { echo 'This checkout holds no lab environment.'; return; }
    net=$(network_of "$slot")
    docker network inspect "$net" >/dev/null 2>&1 && ! owns "$slot" && {
        rm -f "$FILE"; echo "Lab environment $slot belongs to another checkout now; only $FILE removed."; return; }
    for n in "$net" "$(project_of "$slot")-azure_default"; do
        docker network disconnect -f "$n" qcm-registry-cache >/dev/null 2>&1 || true
    done
    for f in local/compose.yml local/compose.azure.yml; do
        docker compose --env-file "$FILE" -f "$f" down >/dev/null 2>&1 || true
    done
    for n in "$net" "$(project_of "$slot")-azure_default"; do
        docker network inspect "$n" >/dev/null 2>&1 || continue
        ids=$(docker ps -aq --filter "network=$n" --filter label=io.floci)
        # shellcheck disable=SC2086
        [[ -z $ids ]] || docker rm -f $ids >/dev/null
    done
    docker network rm "$(project_of "$slot")-azure_default" >/dev/null 2>&1 || true
    # The tools container of this checkout (task tools:up starts it again): it would outlive a removed checkout.
    ids=$(docker ps -aq --filter "label=com.docker.compose.project.working_dir=$ROOT" --filter label=com.docker.compose.service=tools)
    # shellcheck disable=SC2086
    [[ -z $ids ]] || docker rm -f $ids >/dev/null
    # What Floci made for this slot (namespace sN: containers, VPC networks floci-aws-sN-vpc-*, ECR registry data, EC2
    # volume store...): a later owner of the slot starts empty. Slot 0 has no namespace, and its objects stay.
    if ((slot > 0)); then
        ids=$(docker ps -aq --filter "label=floci_namespace=s$slot")
        # shellcheck disable=SC2086
        [[ -z $ids ]] || docker rm -f $ids >/dev/null
        ids=$(docker network ls -q --filter "label=floci_namespace=s$slot")
        # shellcheck disable=SC2086
        [[ -z $ids ]] || docker network rm $ids >/dev/null
        # By label, and by the name prefix for the k3s data volumes floci-aws-sN-eks-<cluster>, which carry no label.
        ids=$({ docker volume ls -q --filter "label=floci_namespace=s$slot"; docker volume ls -q | grep -E "^floci-aws-s$slot-" || true; } | sort -u)
        # shellcheck disable=SC2086
        [[ -z $ids ]] || docker volume rm $ids >/dev/null
    fi
    if docker network inspect "$net" >/dev/null 2>&1 && owns "$slot"; then
        docker network rm "$net" >/dev/null ||
            die "Network $net is still in use (docker network inspect $net): remove its containers first."
    fi
    rm -f "$FILE"
    echo "Lab environment $slot released."
}

case ${1:-} in
    acquire) cmd_acquire ;;
    check) cmd_check ;;
    show) [[ -s $FILE ]] || die 'This checkout has no lab environment yet: run task lab:up.'; grep -v '^#' "$FILE" ;;
    list) cmd_list ;;
    stop-all) cmd_stop_all ;;
    release) cmd_release ;;
    *) sed -n '2,17s/^# \{0,1\}//p' "$0" >&2; exit 2 ;;
esac
