#!/bin/bash
# CGI script behind busybox httpd on 127.0.0.1:$LAB_PORT: POST /cgi-bin/lab with the form body
# token=TOKEN&op=OP&name=value... (GET ?op=ping only, for the health check). TOKEN is /run/lab-token, the
# .local-runtime/lab-token that `task lab:up` writes, so a browser page (CSRF) or another local process without
# access to the checkout cannot drive the Docker socket. Replies text/plain: 200 with the result, 400/403/500 with
# the error. local/lab.sh is the only client.
#   op=ping                                    health check (no token)
#   op=node container= ip= network= dns=       repair a Floci k3s node after a restart (see local/lab.sh prepare)
#   op=port container= port=                   host port that a container publishes for a container port
#   op=aks name= resource=                     host port of a Floci Azure Kubernetes API (checked against its resource id)
#   op=mirror container=                       point a k3s node at the shared image cache (local/compose.cache.yml)
set -uo pipefail

reply() { # status text
    printf 'Status: %s\r\nContent-Type: text/plain\r\n\r\n%s\n' "$1" "$2"
    exit 0
}

declare -A q
body=
if [[ ${REQUEST_METHOD:-} == POST ]]; then
    [[ ${CONTENT_LENGTH:-} =~ ^[0-9]{1,4}$ ]] || reply '400 Bad Request' 'Missing or too large request body.'
    body=$(head -c "$CONTENT_LENGTH")
elif [[ ${REQUEST_METHOD:-} == GET && ${QUERY_STRING:-} == op=ping ]]; then
    body=op=ping
else
    reply '400 Bad Request' 'POST the form body token=...&op=...'
fi
IFS='&' read -ra pairs <<<"$body"
for pair in "${pairs[@]}"; do q[${pair%%=*}]=${pair#*=}; done
if [[ ${q[op]:-} != ping ]]; then
    token=$(cat /run/lab-token 2>/dev/null)
    [[ -n $token && ${q[token]:-} == "$token" ]] || reply '403 Forbidden' 'Missing or wrong token (.local-runtime/lab-token).'
fi

die() { echo "$*" >&2; exit 1; }
quiet() { "$@" >/dev/null 2>&1; }
# Every argument must match its pattern: they end up in docker commands.
param() { # variable regex
    [[ ${q[$1]:-} =~ ^($2)$ ]] || die "Invalid or missing parameter: $1"
    printf -v "$1" '%s' "${q[$1]}"
}
wait_for() { # description seconds command...
    local description=$1 deadline=$((SECONDS + $2)); shift 2
    until "$@"; do
        ((SECONDS < deadline)) || die "Timed out waiting for $description."
        sleep 2
    done
}
running() { [[ $(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null) == true ]]; }
container_created() { [[ $(docker inspect -f '{{.State.Status}}' "$1" 2>/dev/null) =~ ^(running|exited)$ ]]; }

NAME='floci-[A-Za-z0-9_.-]+' IPV4='[0-9]{1,3}(\.[0-9]{1,3}){3}'

op_node() {
    local container ip network dns
    # Only the lab network: a node never joins another network through this API.
    param container "$NAME"; param ip "$IPV4"; param network "${LAB_NETWORK:-aws-local_default}"; param dns "$IPV4(,$IPV4)*"
    wait_for "$container container" 180 container_created "$container"

    # Newer Floci attaches the node to a network of its VPC with the address already pinned and manages the node
    # itself: leave its networks and its token webhook alone and never stop it (a Docker restart of such a node
    # fails: k3s keeps the node address of an earlier cluster with the same name). Older Floci left the node on the
    # lab network with a dynamic address and the webhook on Floci's address: pin the address, point the webhook at
    # floci by name, and restart the node for both.
    local vpc_network
    vpc_network=$(docker inspect -f '{{range $name, $net := .NetworkSettings.Networks}}{{with $net.IPAMConfig}}{{if eq .IPv4Address "'"$ip"'"}}{{$name}} {{end}}{{end}}{{end}}' "$container")
    vpc_network=${vpc_network%% *}
    [[ $vpc_network =~ ^floci-aws-([a-z0-9]+-)?vpc-[A-Za-z0-9_.-]+$ ]] || vpc_network=
    if [[ -n $vpc_network ]]; then
        network=$vpc_network
    else
        local pinned
        pinned=$(docker inspect -f "{{with index .NetworkSettings.Networks \"$network\"}}{{with .IPAMConfig}}{{.IPv4Address}}{{end}}{{end}}" "$container")
        if [[ $pinned != "$ip" ]]; then
            echo "Restoring node address $ip"
            if running "$container"; then docker stop --timeout 30 "$container" >/dev/null; fi
            if [[ -n $(docker inspect -f "{{if index .NetworkSettings.Networks \"$network\"}}yes{{end}}" "$container") ]]; then
                docker network disconnect "$network" "$container" || exit
            fi
            docker network connect --ip "$ip" "$network" "$container" || exit
        fi
    fi

    local floci_id floci_ip
    floci_id=$(docker ps -q --filter "label=com.docker.compose.project=$LAB_PROJECT" --filter label=com.docker.compose.service=floci)
    [[ -n $floci_id ]] || die 'Floci is not running. Start the local lab first.'
    floci_ip=$(docker inspect -f "{{with index .NetworkSettings.Networks \"$network\"}}{{.IPAddress}}{{end}}" "$floci_id")
    [[ -n $floci_ip ]] || die "Floci has no address on the node network $network."
    if [[ -z $vpc_network ]]; then
        local webhook before after
        webhook=$(mktemp)
        docker cp "$container:/etc/token-webhook.yaml" "$webhook" || exit
        before=$(cat "$webhook")
        after=$(sed -E 's#http://[^/[:space:]]+:4566/#http://floci:4566/#g' <<<"$before")
        grep -Eq 'server:[[:space:]]+http://floci:4566/' <<<"$after" || { rm -f "$webhook"; die 'Unexpected token-webhook format.'; }
        if [[ $before != "$after" ]]; then
            if running "$container"; then docker stop --timeout 30 "$container" >/dev/null; fi
            printf '%s\n' "$after" >"$webhook"
            docker cp "$webhook" "$container:/etc/token-webhook.yaml" || exit
        fi
        rm -f "$webhook"
    fi
    running "$container" || docker start "$container" >/dev/null || exit
    running "$container" || die "$container stopped right after its start; see docker logs $container."

    # Floci's synthetic VPC DNS is unreachable by containerd in this lab.
    { docker exec "$container" cat /etc/hosts | grep -Ev '(^|[[:space:]])floci([[:space:]]|$)|^$' || true
      echo "$floci_ip floci"; } | docker exec -i "$container" tee /etc/hosts >/dev/null || exit
    tr ',' '\n' <<<"$dns" | sed 's/^/nameserver /' | docker exec -i "$container" tee /etc/resolv.conf >/dev/null || exit
    wait_for 'Kubernetes API' 180 quiet docker exec "$container" kubectl --request-timeout=5s get --raw=/readyz
    echo 'Node ready'
}

op_port() {
    local container port host
    param container "$NAME"; param port '[0-9]{1,5}'
    host=$(docker port "$container" "$port/tcp" 2>/dev/null | sed -nE 's/.*:([0-9]+)$/\1/p' | head -1)
    [[ -n $host ]] || die "$container publishes no port for $port."
    echo "$host"
}

op_aks() {
    local name resource port
    param name '[A-Za-z0-9-]+'; param resource '[A-Za-z0-9-]+'
    [[ $(docker inspect -f '{{index .Config.Labels "io.floci.resource-id"}}' "$name" 2>/dev/null) == "$resource" ]] ||
        die 'Azure Kubernetes container belongs to another cluster.'
    port=$(docker inspect -f '{{with index .NetworkSettings.Ports "6443/tcp"}}{{(index . 0).HostPort}}{{end}}' "$name")
    [[ -n $port ]] || die 'Azure Kubernetes API has no published port.'
    echo "$port"
}

# Registries the image cache mirrors: <registry>=<upstream>; keep in line with local/compose.cache.yml.
MIRRORS='docker.io=registry-1.docker.io quay.io=quay.io ghcr.io=ghcr.io registry.k8s.io=registry.k8s.io
registry.istio.io=registry.istio.io public.ecr.aws=public.ecr.aws mcr.microsoft.com=mcr.microsoft.com gcr.io=gcr.io'
CACHE=qcm-registry-cache

# Connects the cache to the node's lab network (the AWS lab network, or the Compose network of Floci Azure) and writes
# a containerd hosts.toml per registry into the node. containerd reads them at each pull, so no restart is needed, and
# it falls back to the upstream registry when the cache does not answer.
op_mirror() {
    local container net ip entry registry dir
    param container "$NAME"
    running "$CACHE" || die "No image cache running ($CACHE): task lab:up starts it."
    net=$(docker inspect -f '{{range $name, $_ := .NetworkSettings.Networks}}{{$name}} {{end}}' "$container" | tr ' ' '\n' |
        grep -xE "${LAB_NETWORK:-aws-local_default}|${LAB_PROJECT}_default" | head -1)
    [[ -n $net ]] || die "$container is not on the lab network."
    if [[ -z $(docker inspect -f "{{with index .NetworkSettings.Networks \"$net\"}}x{{end}}" "$CACHE") ]]; then
        # On the lab network a fixed .250: a dynamic address could take Floci's fixed .2 while Floci is stopped.
        local fixed=()
        if [[ $net == "${LAB_NETWORK:-}" ]]; then
            fixed=(--ip "$(docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' "$net" |
                sed -E 's#^([0-9]+\.[0-9]+\.[0-9]+)\.0/.*#\1.250#')")
        fi
        docker network connect "${fixed[@]}" "$net" "$CACHE" || exit
    fi
    ip=$(docker inspect -f "{{with index .NetworkSettings.Networks \"$net\"}}{{.IPAddress}}{{end}}" "$CACHE")
    [[ $ip =~ ^$IPV4$ ]] || die "The image cache has no address on $net."
    dir=/var/lib/rancher/k3s/agent/etc/containerd/certs.d
    for entry in $MIRRORS; do
        registry=${entry%%=*}
        printf 'server = "https://%s"\n\n[host."http://%s:5000/v2/%s"]\n  capabilities = ["pull", "resolve"]\n  override_path = true\n' \
            "${entry#*=}" "$ip" "$registry" |
            docker exec -i "$container" sh -c "mkdir -p $dir/$registry && cat >$dir/$registry/hosts.toml" || exit
    done
    echo "Images through the cache at $ip:5000"
}

out=$(mktemp)
trap 'rm -f "$out"' EXIT
case ${q[op]:-} in
    ping) echo ok >"$out" ;;
    node | port | aks | mirror) ("op_${q[op]}") >"$out" 2>&1 ;;
    *) echo "Unknown op: ${q[op]:-}" >"$out"; false ;;
esac
if (($? == 0)); then status='200 OK'; else status='500 Internal Server Error'; fi
printf 'Status: %s\r\nContent-Type: text/plain\r\n\r\n' "$status"
cat "$out"
