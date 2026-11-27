# kiali

Installs the Kiali operator from the `kiali-operator` chart into the `kiali-operator` namespace; the chart values of the catalog configure the Kiali instance that the operator runs.

## Notes

- With `nexus_charts` set, the `kiali-operator` chart comes from the Nexus chart repository instead of the public one.
- It needs the `istio` component: the Kiali custom resource goes into the `istio-system` namespace.

<!-- BEGIN_CATALOG_DOCS -->
## Parameters

Defaults of `components.helmfile.kiali.vars` in `stacks/catalog/helmfile/kiali.yaml`; a stack overrides any of them.

| Name | Catalog default |
| --- | --- |
| `chart_version` | `2.33.0` |
| `values` | map: `cr` |

Optional, without a catalog default (set by the stack or by `helmfile.vars`): `helm_timeout`, `nexus_charts`.

## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| every helmfile component | `helmfile.vars.nexus_charts` | `nexus` (`.vms[0].internal_address`) | `stacks/catalog/kubemarine/offline.yaml` |
<!-- END_CATALOG_DOCS -->
