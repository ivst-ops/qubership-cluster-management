#!/bin/sh
# Puts a repository chart into helm's content cache, retrying download failures, before helmfile runs helm diff and
# helm upgrade (a helmfile `prepare` hook of the release). Both read the chart from that cache, so a slow chart host
# (GitHub release assets sometimes take longer than helm waits for the response headers) no longer fails the deploy.
# Usage: warm-chart.sh <repo>/<chart> <version>. Never fails the release: after the last attempt helm downloads the
# chart itself and reports its own error. CHART_WARM_ATTEMPTS (default 5) sets the number of attempts.
# Messages go to stdout: helmfile shows the stdout of a hook (`showlogs`) and drops its stderr.
chart=$1
version=$2
attempts=${CHART_WARM_ATTEMPTS:-5}
i=1
while :; do
    # `helm template` fills the content cache (`helm pull` does not); the output itself is not needed.
    if out=$(helm template warm-chart "$chart" --version "$version" 2>&1 >/dev/null); then
        exit 0
    fi
    case $out in
        # A download failure: the connection failed or timed out, or the server answered 429 or 5xx.
        *'Get "'*|*timeout*|*Timeout*|*'connection reset'*|*'connection refused'*|*'no such host'*|*EOF*|*429*|*': '5[0-9][0-9]' '*|*'status code 5'*) ;;
        # Anything else: rendering failed after the download (the chart needs values), so the chart is cached; or the
        # error is not a download one and helm reports it in the next step.
        *) echo "warm-chart: $chart $version: $out"; exit 0 ;;
    esac
    echo "warm-chart: $chart $version, attempt $i of $attempts: $out"
    if [ "$i" -ge "$attempts" ]; then
        echo "warm-chart: $chart $version not cached; helm downloads it itself"
        exit 0
    fi
    sleep $((i * 5))
    i=$((i + 1))
done
