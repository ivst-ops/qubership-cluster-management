# traefik

Installs Traefik from the `traefik` chart into the `traefik` namespace. It routes traffic into the cluster; the readiness examples use it as their ingress controller.

<!-- BEGIN_CATALOG_DOCS -->
## Parameters

Defaults of `components.helmfile.traefik.vars` in `stacks/catalog/helmfile/traefik.yaml`; a stack overrides any of them.

| Name | Catalog default |
| --- | --- |
| `chart_version` | `42.3.0` |
| `values` | map: `service`, `ports`, `providers`, `env`, `additionalArguments` |

Optional, without a catalog default (set by the stack or by `helmfile.vars`): `helm_timeout`.

## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| every helmfile component | `helmfile.vars.nexus_charts` | `nexus` (`.vms[0].internal_address`) | `stacks/catalog/kubemarine/offline.yaml` |
<!-- END_CATALOG_DOCS -->
