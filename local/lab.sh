#!/usr/bin/env bash
# Operator steps that need more than Task does well, called through local/Taskfile.yml (and by OpenTofu):
# Floci node repair and access setup with jq state, the Azure kubeconfig, the Nexus endpoint program of OpenTofu,
# and SSH through the jump host (key file, option arrays, proxy commands shared by several steps). No arguments: usage.
set -euo pipefail
cd "$(dirname "$0")/.."

RUNTIME="$PWD/.local-runtime"
# Ports and the network come from the lab environment of this checkout (QCM_LAB_*: .local-runtime/lab.env, passed
# to the tools container, see local/lab-env.sh); lab commands check it first (lab_required). settings.json gives the
# region and the node DNS servers.
# The lab sidecars of local/compose.yml and local/compose.azure.yml do the Docker work: this image has no Docker.
LAB_API=${LAB_API:-http://127.0.0.1:${QCM_LAB_API_PORT:-}}
LAB_AZURE_API=${LAB_AZURE_API:-http://127.0.0.1:${QCM_LAB_AZURE_API_PORT:-}}
AZURE_HOST=localhost:${QCM_LAB_AZURE_PORT:-}
# Floci prefixes the containers it starts with the slot's namespace (FLOCI_DOCKER_RESOURCE_NAMESPACE): floci-aws-sN-...
FLOCI=floci-aws${QCM_LAB_NAMESPACE:+-$QCM_LAB_NAMESPACE}
ENDPOINT=http://localhost:${QCM_LAB_AWS_PORT:-}
NETWORK=${QCM_LAB_NETWORK:-}
SETTINGS=local/settings.json
[[ -f $SETTINGS ]] || SETTINGS=local/settings.example.json
REGION=$(jq -r .region "$SETTINGS")
export NO_PROXY="${NO_PROXY:+$NO_PROXY,}localhost,127.0.0.1,::1,floci"
export no_proxy=$NO_PROXY AWS_PAGER=""
mkdir -p "$RUNTIME"

die() { echo "$*" >&2; exit 1; }
quiet() { "$@" >/dev/null 2>&1; }
awsl() { aws --endpoint-url "$ENDPOINT" --region "$REGION" --no-cli-pager "$@"; }

wait_for() { # description seconds command...
    local description=$1 deadline=$((SECONDS + $2)); shift 2
    until "$@"; do
        ((SECONDS < deadline)) || die "Timed out waiting for $description."
        sleep 2
    done
}

# Lab commands act on the lab of this checkout only: without its slot they would reach another checkout's lab.
lab_required() {
    [[ -n ${QCM_LAB_SLOT:-} ]] ||
        die 'This checkout has no lab environment in the tools container: run task lab:up on the host.'
}

check_stack() { [[ ${1:-} =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die "Invalid stack name: ${1:-}"; }

# Prints the component's resolved configuration; Atmos messages go to stderr, not into the JSON.
describe() { # component stack [atmos args...]
    local file; file=$(mktemp)
    atmos describe component "$1" -s "$2" --format json --file "$file" "${@:3}" >&2 ||
        { rm -f "$file"; die "Cannot describe $1 for stack $2."; }
    [[ -s $file ]] || { rm -f "$file"; die "Atmos wrote no configuration for stack $2."; }
    cat "$file"; rm -f "$file"
}

# POSTs a lab sidecar operation with the token of `task lab:up`: lab_post URL OP [name=value...]; prints the reply.
lab_post() {
    local url=$1 op=$2 token; shift 2
    token=$(cat "$RUNTIME/lab-token" 2>/dev/null) || { echo "No $RUNTIME/lab-token: run task lab:up." >&2; return 1; }
    # The body on stdin: the token stays out of the process list.
    printf 'token=%s&op=%s%s' "$token" "$op" "$(printf '&%s' "$@")" |
        curl --noproxy '*' -sS --fail-with-body --max-time 600 --data-binary @- "$url/cgi-bin/lab"
}

# Calls a lab sidecar operation (local/lab/lab-api.sh): lab_call URL OP [name=value...]; prints its reply.
lab_call() {
    local url=$1 op=$2 reply; shift 2
    reply=$(lab_post "$url" "$op" "$@") ||
        die "${reply:+$reply$'\n'}Lab sidecar $url failed ($op). Is the emulator started on the host" \
            "(task lab:up, or task lab:up CLOUD=azure)?"
    printf '%s\n' "$reply"
}

# Public images through the shared cache (local/compose.cache.yml); a lab without it pulls from the Internet.
# Waits for a kube-system deployment. One restart on a timeout: a pull that lost a race in the shared image cache
# (two labs fetching the same image) sits in ImagePullBackOff for minutes; new pods pull again at once.
rollout_ready() { # kubeconfig, deployment
    kubectl --kubeconfig "$1" rollout status "deployment/$2" -n kube-system --timeout=180s && return
    echo "Deployment $2 not ready: restarting it once (an image pull may have failed)." >&2
    kubectl --kubeconfig "$1" rollout restart "deployment/$2" -n kube-system
    kubectl --kubeconfig "$1" rollout status "deployment/$2" -n kube-system --timeout=180s
}

mirror() { # sidecar URL, node container
    lab_post "$1" mirror "container=$2" || echo "Image cache not used; the node pulls from the upstream registries." >&2
}

cmd_prepare() {
    local stack=$1 config identity cluster container profile user kubeconfig
    check_stack "$stack"; lab_required
    export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
    config=$(describe argocd "$stack")
    [[ $(jq -r '.settings.local_lab // false' <<<"$config") == true ]] || die "Stack $stack is not a local Floci stack."
    identity=$(jq -r '.vars.environment // empty' <<<"$config")
    [[ -n $identity ]] || die "Stack $stack does not define environment."
    cluster="$identity-eks" container="$FLOCI-eks-$identity-eks"
    profile="floci-$identity" user="$identity-kubectl"
    kubeconfig="$RUNTIME/kubeconfig-$stack.yaml"

    # Node address: the EC2 record preserves it even for a stopped k3s container.
    local description generation nodes="$RUNTIME/nodes.json" ip
    description=$(awsl eks describe-cluster --name "$cluster" --output json)
    generation=$(jq -r .cluster.createdAt <<<"$description")
    [[ -f $nodes ]] || echo '{}' >"$nodes"
    ip=$(jq -r --arg s "$stack" --arg g "$generation" '.[$s] | select(.generation == $g) | .ip // empty' "$nodes")
    if [[ -z $ip ]]; then
        local ips
        ips=$(awsl ec2 describe-instances --output json --filters \
            "Name=vpc-id,Values=$(jq -r .cluster.resourcesVpcConfig.vpcId <<<"$description")" \
            Name=instance-state-name,Values=running "Name=tag:eks:cluster-name,Values=$cluster" |
            jq -r '.Reservations[].Instances[].PrivateIpAddress // empty')
        [[ $(grep -c . <<<"$ips") == 1 ]] || die "Expected one local k3s node for $stack; found $(grep -c . <<<"$ips")."
        ip=$ips
    fi
    jq --arg s "$stack" --arg g "$generation" --arg ip "$ip" '.[$s] = {ip: $ip, generation: $g}' "$nodes" >"$nodes.tmp"
    mv "$nodes.tmp" "$nodes"

    # The sidecar pins the node address, points the token webhook and DNS at floci and waits for the API.
    lab_call "$LAB_API" node "container=$container" "ip=$ip" "network=$NETWORK" \
        "dns=$(jq -r '.dnsServers | join(",")' "$SETTINGS")"
    mirror "$LAB_API" "$container"

    # Access: an AWS profile for the OpenTofu-created IAM user and an exec kubeconfig.
    local expected="arn:aws:iam::000000000000:user/$user" saved key
    if [[ $(awsl sts get-caller-identity --profile "$profile" --query Arn --output text 2>/dev/null) != "$expected" ]]; then
        awsl iam get-user --user-name "$user" >/dev/null
        saved=$(aws configure get aws_access_key_id --profile "$profile" 2>/dev/null || true)
        if [[ -n $saved ]] && awsl iam list-access-keys --user-name "$user" --output json |
            jq -e --arg k "$saved" 'any(.AccessKeyMetadata[]; .AccessKeyId == $k)' >/dev/null; then
            die "Saved credentials exist but do not authenticate. Check profile $profile."
        fi
        echo "Creating local access for $user"
        key=$(awsl iam create-access-key --user-name "$user" --output json)
        [[ -n $(jq -r '.AccessKey.AccessKeyId // empty' <<<"$key") && -n $(jq -r '.AccessKey.SecretAccessKey // empty' <<<"$key") ]] ||
            die 'Floci returned incomplete credentials.'
        aws configure set aws_access_key_id "$(jq -r .AccessKey.AccessKeyId <<<"$key")" --profile "$profile"
        aws configure set aws_secret_access_key "$(jq -r .AccessKey.SecretAccessKey <<<"$key")" --profile "$profile"
        aws configure set region "$REGION" --profile "$profile"
        aws configure set endpoint_url "$ENDPOINT" --profile "$profile"
        [[ $(awsl sts get-caller-identity --profile "$profile" --query Arn --output text) == "$expected" ]] ||
            die 'Unexpected identity after configuring the AWS profile.'
    fi
    awsl eks update-kubeconfig --name "$cluster" --profile "$profile" --kubeconfig "$kubeconfig" \
        --alias "$profile" --user-alias "$profile" >/dev/null
    kubectl --kubeconfig "$kubeconfig" config set-credentials "$profile" \
        --exec-command=aws --exec-api-version=client.authentication.k8s.io/v1beta1 \
        --exec-arg=--region "--exec-arg=$REGION" --exec-arg=eks --exec-arg=get-token \
        --exec-arg=--cluster-name "--exec-arg=$cluster" --exec-arg=--profile "--exec-arg=$profile" \
        --exec-arg=--output --exec-arg=json >/dev/null
    wait_for "$stack authentication" 180 quiet kubectl --kubeconfig "$kubeconfig" --request-timeout=5s get --raw=/readyz
    kubectl --kubeconfig "$kubeconfig" wait --for=condition=Ready nodes --all --timeout=120s
    rollout_ready "$kubeconfig" coredns
    echo "$stack is ready. Kubeconfig: $kubeconfig"
}

cmd_prepare_azure() {
    local stack=$1 config identity subscription credentials kubeconfig name port path="$RUNTIME/kubeconfig-$1.yaml"
    check_stack "$stack"; lab_required
    config=$(describe argocd "$stack")
    [[ $(jq -r '.settings.local_azure_lab // false' <<<"$config") == true &&
        $(jq -r '.env.ARM_METADATA_HOSTNAME // empty' <<<"$config") == "$AZURE_HOST" ]] ||
        die 'This command requires the local Floci Azure stack.'
    identity=$(jq -r .vars.environment <<<"$config")
    subscription=$(jq -r .env.ARM_SUBSCRIPTION_ID <<<"$config")
    credentials=$(curl --noproxy '*' -fsS -X POST -H 'Content-Type: application/json' -d '{}' \
        "http://$AZURE_HOST/subscriptions/$subscription/resourceGroups/$identity-rg/providers/Microsoft.ContainerService/managedClusters/$identity-aks/listClusterAdminCredential?api-version=2024-04-01")
    kubeconfig=$(jq -r '.kubeconfigs[0].value // empty' <<<"$credentials" | base64 -d)
    [[ -n $kubeconfig ]] || die 'Floci Azure returned no kubeconfig.'
    # Floci returns a Docker-only hostname. Use this cluster's published API port instead.
    name=$(sed -nE 's#^[[:space:]]*server:[[:space:]]*https://([a-zA-Z0-9-]+):6443[[:space:]]*$#\1#p' <<<"$kubeconfig" | head -1)
    [[ -n $name ]] || die 'Unexpected Floci Azure kubeconfig server.'
    port=$(lab_call "$LAB_AZURE_API" aks "name=$name" "resource=$identity-aks")
    mirror "$LAB_AZURE_API" "$name"
    printf '%s\n' "${kubeconfig//"https://$name:6443"/"https://localhost:$port"}" >"$path"
    kubectl --kubeconfig "$path" wait --for=condition=Ready nodes --all --timeout=180s
    rollout_ready "$path" coredns
    echo "$stack is ready. Kubeconfig: $path"
}

# OpenTofu external program of components/terraform/aws/nexus (readiness.tf) for the local lab: reads
# {"instance_id": "i-..."} on stdin, waits up to NEXUS_ENDPOINT_TIMEOUT seconds (default 600: Floci publishes the
# port only after the instance has booted, which is slow on small hosts) for the Nexus port 8081 and writes
# {"url": "<readiness URL>"} on stdout. Messages go to stderr; the lab sidecar does the Docker lookup.
cmd_nexus_endpoint_json() {
    local id port timeout=${NEXUS_ENDPOINT_TIMEOUT:-600} deadline
    lab_required
    [[ $timeout =~ ^[0-9]+$ ]] || die 'NEXUS_ENDPOINT_TIMEOUT must be a number of seconds.'
    deadline=$((SECONDS + timeout))
    id=$(jq -r '.instance_id // empty')
    [[ $id =~ ^i-[a-f0-9]+$ ]] || die 'Expected a valid instance_id in the OpenTofu JSON query.'
    until port=$(lab_post "$LAB_API" port "container=$FLOCI-ec2-fwd-$id-8081" port=8081 2>/dev/null); do
        ((SECONDS < deadline)) ||
            die "No HTTP port published by $FLOCI-ec2-fwd-$id-8081 within $timeout seconds. Is the lab started (task lab:up)?"
        sleep 5
    done
    jq -cn --arg url "http://127.0.0.1:$port/service/rest/v1/status/writable" '{url: $url}'
}

# --- VM installation (docs/vm-installation.md), through local/Taskfile.yml under `task -d local secrets:exec` ---------

# Jump host, Nexus, nodes and tunnel port from the kubemarine component; "(computed)" = not applied yet.
vm_context() {
    local config; config=$(describe kubemarine "$1")
    JUMP=$(jq -r '(.vars.jump_host | objects | .address) // empty' <<<"$config")
    NEXUS=$(jq -r '.vars.nexus_address | select(. != "(computed)") // empty' <<<"$config")
    NODES=$(jq -c '.vars.nodes | arrays' <<<"$config")
    PORT=$(jq -r '.settings.tunnel_port // 1080' <<<"$config")
    SSH_USER=$(jq -r '.vars.ssh_user // "ubuntu"' <<<"$config")
    [[ -n $JUMP ]] || die "Stack $1 has no jump host yet: apply jump-host first."
}

# The private key from the secrets (secrets:exec) as a file for this run only.
ssh_setup() {
    [[ -n ${TF_VAR_ssh_private_key:-} ]] ||
        die "No SSH key: run under the stack secrets: task -d local secrets:exec STACK=$1 -- task -d local ..."
    KEY=$RUNTIME/ssh-$$.key
    (umask 077 && printf '%s\n' "$TF_VAR_ssh_private_key" >"$KEY")
    trap 'rm -f "$KEY"' EXIT
    SSH_OPTS=(-i "$KEY" -o IdentitiesOnly=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new
        -o "UserKnownHostsFile=$RUNTIME/known_hosts-$1")
}
on_jump() { ssh "${SSH_OPTS[@]}" "$SSH_USER@$JUMP" "$@"; }
through_jump() { # private address, command...
    ssh "${SSH_OPTS[@]}" -o "ProxyCommand=ssh ${SSH_OPTS[*]} -W %h:%p $SSH_USER@$JUMP" "$SSH_USER@$1" "${@:2}"
}
# Unix sockets are limited to 108 chars and ssh appends 17 while binding: a checkout path would not fit.
# local/Taskfile.yml (tunnel:stop) uses the same path.
tunnel_sock() { echo "/tmp/qcm-tunnel-$1.sock"; }
tunnel_running() { ssh -S "$(tunnel_sock "$1")" -O check tunnel 2>/dev/null; }
tunnel_required() {
    tunnel_running "$1" ||
        die "Start the tunnel first: task -d local secrets:exec STACK=$1 -- task -d local tunnel STACK=$1"
}
# curl reads only the lowercase http_proxy; Go tools read either.
proxy_env() {
    export http_proxy=socks5://127.0.0.1:$PORT
    export HTTP_PROXY=$http_proxy HTTPS_PROXY=$http_proxy https_proxy=$http_proxy
}

cmd_tunnel() {
    local stack=$1; check_stack "$stack"
    vm_context "$stack"; ssh_setup "$stack"
    tunnel_running "$stack" && { echo "Tunnel for $stack is already running on 127.0.0.1:$PORT."; return; }
    wait_for "SSH on the jump host $JUMP" 300 quiet on_jump true
    ssh "${SSH_OPTS[@]}" -f -N -M -S "$(tunnel_sock "$stack")" -D "127.0.0.1:$PORT" \
        -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 "$SSH_USER@$JUMP"
    echo "SOCKS proxy socks5://127.0.0.1:$PORT into the $stack network (stop: task -d local tunnel:stop STACK=$stack)."
}

cmd_nexus_install() {
    local stack=$1 bundle=${BUNDLE_DIR:-$RUNTIME/bundle}; check_stack "$stack"
    vm_context "$stack"; ssh_setup "$stack"
    [[ -n $NEXUS ]] || die "Stack $stack has no Nexus VM yet: apply nexus first."
    [[ -f $bundle/nexus.tar.gz ]] || die "No bundle in $bundle; run task bundle on the host."
    wait_for "SSH on Nexus $NEXUS" 300 quiet through_jump "$NEXUS" true
    echo "Copying Nexus to $NEXUS through $JUMP"
    through_jump "$NEXUS" 'cat >/tmp/nexus.tar.gz' <"$bundle/nexus.tar.gz"
    through_jump "$NEXUS" sudo bash -s <bundle/nexus-install.sh
    echo "Nexus is starting on $NEXUS; nexus:load waits for it."
}

cmd_nexus_load() {
    local stack=$1; check_stack "$stack"
    vm_context "$stack"
    [[ -n $NEXUS ]] || die "Stack $stack has no Nexus VM yet: apply nexus first."
    tunnel_required "$stack"
    proxy_env
    NEXUS_URL=http://$NEXUS:8081 bash bundle/load.sh
}

# A shell or a command on a private VM (Nexus, a node) through the jump host.
cmd_ssh() {
    local stack=$1 host=${2:-}; check_stack "$stack"
    [[ -n $host ]] || die 'Usage: task -d local ssh STACK=<stack> HOST=<private address> [-- command]'
    vm_context "$stack"; ssh_setup "$stack"
    through_jump "$host" "${@:3}"
}

# After kubemarine apply: kubeconfig from the first control-plane, reaching the API through the tunnel.
cmd_prepare_vms() {
    local stack=$1 cp kubeconfig; check_stack "$stack"
    vm_context "$stack"; ssh_setup "$stack"
    cp=$(jq -r '[.[] | select(.roles | index("control-plane"))][0].internal_address // empty' <<<"${NODES:-[]}")
    [[ -n $cp ]] || die "Stack $stack has no control-plane node yet: apply vms first."
    tunnel_required "$stack"
    kubeconfig=$RUNTIME/kubeconfig-$stack.yaml
    through_jump "$cp" sudo cat /etc/kubernetes/admin.conf >"$kubeconfig.tmp"
    yq -i ".clusters[0].cluster.server = \"https://$cp:6443\" |
        .clusters[0].cluster.\"proxy-url\" = \"socks5://127.0.0.1:$PORT\"" "$kubeconfig.tmp"
    chmod 600 "$kubeconfig.tmp" && mv "$kubeconfig.tmp" "$kubeconfig"
    kubectl --kubeconfig "$kubeconfig" wait --for=condition=Ready nodes --all --timeout=300s
    echo "$stack is ready. Kubeconfig: $kubeconfig"
}

case ${1:-} in
    prepare) cmd_prepare "${2:-}" ;;
    prepare-azure) cmd_prepare_azure "${2:-}" ;;
    nexus-endpoint-json) cmd_nexus_endpoint_json ;;
    tunnel) cmd_tunnel "${2:-}" ;;
    nexus-install) cmd_nexus_install "${2:-}" ;;
    nexus-load) cmd_nexus_load "${2:-}" ;;
    prepare-vms) cmd_prepare_vms "${2:-}" ;;
    ssh) shift; cmd_ssh "$@" ;;
    *) cat >&2 <<'EOF'
Usage: local/lab.sh <command>
The Bash part of the operator tasks; run them through local/Taskfile.yml (`task -d local --list`):
  prepare STACK          after Kubernetes apply: repair the k3s node, configure AWS profile and kubeconfig
  prepare-azure STACK    write the kubeconfig for a local Floci Azure cluster
  nexus-endpoint-json    OpenTofu external program: {"instance_id"} on stdin -> {"url"} of the Floci Nexus
VM installation (docs/vm-installation.md); SSH commands need the stack secrets (task -d local secrets:exec):
  tunnel STACK           SOCKS proxy through the jump host into the private network
  nexus-install STACK    copy Nexus from the bundle to its VM through the jump host and start it
  nexus-load STACK       create the Nexus repositories and upload the bundle (through the tunnel)
  prepare-vms STACK      after kubemarine: kubeconfig from the control plane, API through the tunnel
  ssh STACK ADDRESS [CMD] shell or command on a private VM through the jump host
EOF
       exit 2 ;;
esac
