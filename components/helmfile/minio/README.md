# minio

Installs MinIO from the `minio` chart into the `storage` namespace and creates its first bucket with the local `minio-bucket` chart, which waits for MinIO.

## Notes

- With `nexus_charts` set, the `minio` chart comes from the Nexus chart repository instead of the public one.

<!-- BEGIN_CATALOG_DOCS -->
## Parameters

Defaults of `components.helmfile.minio.vars` in `stacks/catalog/helmfile/minio.yaml`; a stack overrides any of them.

| Name | Catalog default |
| --- | --- |
| `chart_version` | `5.4.0` |
| `values` | map: `mode`, `image`, `mcImage`, `replicas`, `fullnameOverride`, `persistence`, `resources`, `consoleService`, `users` |
| `bucket_values` | map: `bucket` |

Optional, without a catalog default (set by the stack or by `helmfile.vars`): `helm_timeout`, `nexus_charts`.

## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| every helmfile component | `helmfile.vars.nexus_charts` | `nexus` (`.vms[0].internal_address`) | `stacks/catalog/kubemarine/offline.yaml` |
<!-- END_CATALOG_DOCS -->
