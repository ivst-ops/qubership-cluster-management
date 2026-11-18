#!/usr/bin/env bash
# Downloads everything listed in bundle/manifest.yaml into one directory that bundle/load.sh uploads into Nexus.
# Needs Internet, curl, helm, crane and yq (all in the tools image). Re-running skips what is already there.
# Usually started as `task bundle` from the host, which then builds the node packages (apt/): `task bundle:apt`.
#   BUNDLE_DIR       output directory (default .local-runtime/bundle)
#   BUNDLE_MANIFEST  manifest to read (default bundle/manifest.yaml)
set -euo pipefail
cd "$(dirname "$0")/.."

out=${BUNDLE_DIR:-$PWD/.local-runtime/bundle}
manifest=${BUNDLE_MANIFEST:-bundle/manifest.yaml}
m() { yq -r "$1" "$manifest"; }
fetch() { [[ -s $2 ]] || { mkdir -p "$(dirname "$2")"; curl -fsSL --retry 3 -o "$2.part" "$1" && mv "$2.part" "$2"; }; }
# A target image name as a file name: calico/node:v1 -> calico_node_v1.tar
image_file() { echo "$out/images/$(tr '/:' '__' <<<"$1").tar"; }

mkdir -p "$out"
cp "$manifest" "$out/manifest.yaml"

echo "Nexus $(m .nexus.version)"
fetch "$(m .nexus.source)" "$out/nexus.tar.gz"

echo 'Kubemarine files'
m '.files | to_entries[] | .key + " " + .value' | while read -r path url; do fetch "$url" "$out/files/$path"; done

# Node packages come from a container of the node OS, which the host starts (bundle/compose.yml): write its inputs.
printf 'OS_IMAGE=%s\nOS_PACKAGES=%s\n' "$(m .os.image)" "$(m '.os.packages | join(" ")')" >"$out/apt.env"

echo 'Helm charts'
mkdir -p "$out/charts"
m '.charts[] | .chart + " " + .version + " " + .repository' | while read -r chart version repository; do
    [[ -s $out/charts/$chart-$version.tgz ]] ||
        helm pull "$chart" --repo "$repository" --version "$version" --destination "$out/charts"
done
helm repo index "$out/charts"

echo 'Images'
m '(.images | to_entries[] | .key + " " + .value), (.app_images[] | . + " " + .)' | while read -r target source; do
    file=$(image_file "$target")
    [[ -s $file ]] || { mkdir -p "$out/images"; crane pull --platform linux/amd64 "$source" "$file.part" && mv "$file.part" "$file"; }
done

if [[ -s $out/apt/Packages ]]; then
    echo "Bundle ready: $out ($(du -sh "$out" | cut -f1)). Move it as is (or as one tar) to the operator machine."
else
    echo "Bundle ready except node packages ($(m .os.image)). From the host shell in the repository root, run:"
    echo "  task bundle:apt${BUNDLE_DIR:+ BUNDLE_DIR=${out#"$PWD/"}}"
fi
