# istio

Installs Istio from the `base` and `istiod` charts into the `istio-system` namespace; `istiod` waits for `istio-base`.

## Notes

- With `nexus_charts` set, the `base` and `istiod` charts come from the Nexus chart repository instead of the public one.

<!-- BEGIN_CATALOG_DOCS -->
## Parameters

Defaults of `components.helmfile.istio.vars` in `stacks/catalog/helmfile/istio.yaml`; a stack overrides any of them.

| Name | Catalog default |
| --- | --- |
| `chart_version` | `1.30.6` |
| `base_values` | map: `defaultRevision` |
| `values` | `{}` |

Optional, without a catalog default (set by the stack or by `helmfile.vars`): `helm_timeout`, `nexus_charts`.

## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| every helmfile component | `helmfile.vars.nexus_charts` | `nexus` (`.vms[0].internal_address`) | `stacks/catalog/kubemarine/offline.yaml` |
<!-- END_CATALOG_DOCS -->
