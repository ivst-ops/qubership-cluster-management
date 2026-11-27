# argocd

Installs Argo CD from the `argo-cd` chart into the `argocd` namespace.

## Notes

- With `nexus_charts` set, the `argo-cd` chart comes from the Nexus chart repository instead of the public one.

<!-- BEGIN_CATALOG_DOCS -->
## Parameters

Defaults of `components.helmfile.argocd.vars` in `stacks/catalog/helmfile/argocd.yaml`; a stack overrides any of them.

| Name | Catalog default |
| --- | --- |
| `chart_version` | `10.10.3` |
| `values` | map: `configs`, `server` |

Optional, without a catalog default (set by the stack or by `helmfile.vars`): `helm_timeout`, `nexus_charts`.

## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| every helmfile component | `helmfile.vars.nexus_charts` | `nexus` (`.vms[0].internal_address`) | `stacks/catalog/kubemarine/offline.yaml` |
<!-- END_CATALOG_DOCS -->
