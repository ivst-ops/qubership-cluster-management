#!/usr/bin/env bash
# Node packages for the bundle: runs in a clean container of the node OS release (bundle/compose.yml) and writes
# the dependency closure of OS_PACKAGES with a Packages index into /debs. Virtual packages have no candidate.
set -euo pipefail
[[ -n ${OS_PACKAGES:-} ]] || { echo 'OS_PACKAGES is empty: run bundle/build.sh first.' >&2; exit 1; }
apt-get update -qq && apt-get install -y -qq --no-install-recommends apt-utils >/dev/null
find /debs -mindepth 1 -delete
cd /debs
# shellcheck disable=SC2086 # OS_PACKAGES is a space-separated list
apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces \
    --no-enhances $OS_PACKAGES | grep -E '^[a-z0-9]' | sort -u >/tmp/names
apt-get download -qq $(xargs apt-cache policy </tmp/names |
    awk '/^[a-z0-9].*:$/ {n=$1} /Candidate:/ && $2 != "(none)" {sub(":$","",n); print n}')
apt-ftparchive packages . >Packages
chmod -R a+rwX /debs
