#!/bin/sh
# Generated blocks of the component and module READMEs, run in the docs-lint image by `task docs:generate`
# (MODE generate, read-write checkout) and `task docs:check` (MODE check, read-only checkout). Shell, not Task: Task is
# not in the image, and this is only the loop over the directories; the content comes from .terraform-docs.yml,
# docs/deps.yq and docs/helmfile-params.yq.
set -eu
mode=$1
work=/tmp/docs-module
rc=0
catalog=$(find stacks/catalog -name '*.yaml' | LC_ALL=C sort)

fail() { echo "docs:$mode: $*"; rc=1; }

# A README starts with "# <title>" and has at least one paragraph of hand-written text before the generated block.
purpose() {
  awk -v t="# $2" '
    NR == 1 && $0 != t { bad = 1; exit }
    /^<!-- BEGIN_(TF|CATALOG)_DOCS -->/ { exit }
    NR > 1 && NF && $0 !~ /^(#|<|\||- |```)/ { text = 1 }
    END { exit (bad || !text) ? 1 : 0 }' "$1/README.md"
}

# The "Component dependencies" table of component $2 (kind $1); $3 is the text when the catalog declares none.
deps() {
  rows=$(for f in $catalog; do FILE=$f KIND=$1 COMPONENT=$2 yq -r --from-file docs/deps.yq "$f"; done)
  if [ -n "$rows" ]; then
    printf '| Instance | Declared in | Needs component (output) | Catalog file |\n| --- | --- | --- | --- |\n%s\n' "$rows"
  else
    printf '%s\n' "$3"
  fi
}

# Replaces the block between BEGIN_$2 and END_$2 of README $1 with file $3, on stdout.
inject() {
  awk -v b="<!-- BEGIN_$2 -->" -v e="<!-- END_$2 -->" -v f="$3" '
    $0 == b { print; while ((getline l < f) > 0) print l; skip = 1; next }
    $0 == e { skip = 0 }
    !skip' "$1"
}

for m in $(find components/terraform providers -name versions.tf -not -path '*/.terraform/*' | sed 's|/versions.tf$||' | LC_ALL=C sort); do
  case $m in
    providers/*) title=${m##*/}; none='None. This is a child module; the calling component passes every input.' ;;
    *) title=${m#components/terraform/}; none='None declared in the stack catalog.' ;;
  esac
  [ -f "$m/README.md" ] || { fail "$m/README.md is missing"; continue; }
  purpose "$m" "$title" || fail "$m/README.md needs \"# $title\" and a hand-written purpose before the generated block"
  rm -rf "$work" && mkdir -p "$work"
  tar -C "$m" --exclude=.terraform -cf - . | tar -C "$work" -xf -
  deps terraform "$title" "$none" > "$work/.docs-deps.md"
  if [ "$mode" = check ]; then
    terraform-docs -c "$PWD/.terraform-docs.yml" --output-check "$work" > /dev/null 2>&1 || fail "$m/README.md is out of date"
  else
    terraform-docs -c "$PWD/.terraform-docs.yml" "$work" > /dev/null && cp "$work/README.md" "$m/README.md"
  fi
done

# Helmfile components have no variables.tf: the generated block lists the catalog parameters and dependencies.
for m in $(find components/helmfile -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort); do
  name=${m##*/}
  file=stacks/catalog/helmfile/$name.yaml
  [ -f "$m/README.md" ] || { fail "$m/README.md is missing"; continue; }
  purpose "$m" "$name" || fail "$m/README.md needs \"# $name\" and a hand-written purpose before the generated block"
  grep -qx '<!-- BEGIN_CATALOG_DOCS -->' "$m/README.md" || { fail "$m/README.md has no BEGIN_CATALOG_DOCS marker"; continue; }
  rm -rf "$work" && mkdir -p "$work"
  {
    echo '## Parameters'
    echo
    if [ -f "$file" ]; then
      echo "Defaults of \`components.helmfile.$name.vars\` in \`$file\`; a stack overrides any of them."
      echo
      echo '| Name | Catalog default |'
      echo '| --- | --- |'
      NAME=$name yq -r --from-file docs/helmfile-params.yq "$file"
    else
      echo 'None in the stack catalog.'
    fi
    # Values read with a default in helmfile.yaml.gotmpl (`.Values | get "<key>" <default>`) and absent from the catalog.
    keys=$(grep -ohE 'get "[a-z_]+"' "$m/helmfile.yaml.gotmpl" | sed -E 's/get "([a-z_]+)"/\1/' | LC_ALL=C sort -u)
    optional=
    for k in $keys; do
      [ -f "$file" ] && [ "$(NAME=$name K=$k yq -r '.components.helmfile[strenv(NAME)].vars | has(strenv(K))' "$file")" = true ] && continue
      optional="$optional${optional:+, }\`$k\`"
    done
    if [ -n "$optional" ]; then
      echo
      echo "Optional, without a catalog default (set by the stack or by \`helmfile.vars\`): $optional."
    fi
    echo
    echo '## Component dependencies'
    echo
    deps helmfile "$name" 'None declared in the stack catalog.'
  } > "$work/block.md"
  inject "$m/README.md" CATALOG_DOCS "$work/block.md" > "$work/README.md"
  if [ "$mode" = check ]; then
    cmp -s "$m/README.md" "$work/README.md" || fail "$m/README.md is out of date"
  else
    cp "$work/README.md" "$m/README.md"
  fi
done

[ "$rc" = 0 ] && echo "docs:$mode: ok" || echo "docs:$mode: run \`task docs:generate\` and commit the READMEs"
exit "$rc"
