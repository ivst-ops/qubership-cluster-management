#!/bin/sh
# Fetches one image through the image cache (zot) so that it is synced from upstream before the labs ask for it.
# Runs in a container on the cache network (task lab:cache-warm): flock on a volume is the lock of the Docker host.
# Usage: cache-warm.sh <registry>/<repository>:<tag>
set -eu
ref=$1 reg=${1%%/*}
rest=${ref#*/} repo=$reg/${rest%:*} tag=${rest##*:}
cache=http://qcm-registry-cache:5000/v2/$repo
exec 9>/lock/warm
flock 9
# Cached already: the tag list is answered locally, a manifest request would ask the upstream registry again.
if wget -qO- "$cache/tags/list" 2>/dev/null | grep -q "\"$tag\""; then echo "cached   $ref"; exit 0; fi
accept='application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json'
if wget -qO /dev/null --header "Accept: $accept" "$cache/manifests/$tag"; then echo "warmed   $ref"; else echo "skipped  $ref (not available through the cache)"; fi
