# headlamp

Installs the Headlamp Kubernetes web console from the `headlamp` chart into the `headlamp` namespace.

## Notes

- With `nexus_charts` set, the `headlamp` chart comes from the Nexus chart repository instead of the public one.
- It needs the `minio` component: the catalog values create a Role in the `storage` namespace.

<!-- BEGIN_CATALOG_DOCS -->
## Parameters

Defaults of `components.helmfile.headlamp.vars` in `stacks/catalog/helmfile/headlamp.yaml`; a stack overrides any of them.

| Name | Catalog default |
| --- | --- |
| `chart_version` | `0.46.0` |
| `values` | map: `fullnameOverride`, `image`, `service`, `serviceAccount`, `clusterRoleBinding`, `extraManifests` |

Optional, without a catalog default (set by the stack or by `helmfile.vars`): `helm_timeout`, `nexus_charts`.

## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| every helmfile component | `helmfile.vars.nexus_charts` | `nexus` (`.vms[0].internal_address`) | `stacks/catalog/kubemarine/offline.yaml` |
<!-- END_CATALOG_DOCS -->
