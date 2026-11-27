# kubemarine

Builds the Kubemarine inventory from the outputs of the VM components and installs Kubernetes on the VMs over SSH through the jump host, with packages, binaries and images served by Nexus.

## Notes

- The installation runs once per environment. Later inventory changes go through Kubemarine procedures (`add_node`, `upgrade`); a reinstall uses `-replace=terraform_data.install`.
- It runs in the tools image built from the root `Dockerfile`, where Kubemarine is installed.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| `kubemarine` | `vars.nodes` | `vms` (`.vms`) | `stacks/catalog/kubemarine/install.yaml` |
| `kubemarine` | `vars.jump_host` | `jump-host` (`.vms[0]`) | `stacks/catalog/kubemarine/install.yaml` |
| `kubemarine` | `vars.nexus_address` | `nexus` (`.vms[0].internal_address`) | `stacks/catalog/kubemarine/install.yaml` |

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.install](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; names the Kubemarine cluster (`<environment>.local`) and its working directory | `string` | n/a | yes |
| <a name="input_jump_host"></a> [jump\_host](#input\_jump\_host) | Jump host VM (any `<cloud>/vms` output entry); Kubemarine reaches the nodes through it | <pre>object({<br/>    address = string<br/>  })</pre> | n/a | yes |
| <a name="input_mirrored_registries"></a> [mirrored\_registries](#input\_mirrored\_registries) | Registries of application images; containerd pulls `<registry>/<path>` from Nexus (`bundle/manifest.yaml` `app_images`) | `list(string)` | n/a | yes |
| <a name="input_nexus_address"></a> [nexus\_address](#input\_nexus\_address) | Private address of the Nexus VM loaded by `bundle/load.sh` | `string` | n/a | yes |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Cluster VMs as output by any `<cloud>/vms` component; roles are Kubemarine roles | <pre>list(object({<br/>    name             = string<br/>    roles            = list(string)<br/>    address          = string<br/>    internal_address = string<br/>  }))</pre> | n/a | yes |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | Key for the jump host and the nodes (TF\_VAR\_ssh\_private\_key from sops exec-env) | `string` | n/a | yes |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_kubemarine"></a> [kubemarine](#input\_kubemarine) | Extra `cluster.yaml` fields (for example `services`, `plugins`); the generated `nodes`, `gateway_nodes`, `registry`, package repositories and containerd mirrors are applied on top, so of the generated fields only `cluster_name` can be overridden | `any` | `{}` | no |
| <a name="input_ssh_user"></a> [ssh\_user](#input\_ssh\_user) | User that Kubemarine connects as over SSH, on the nodes and the jump host | `string` | `"ubuntu"` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, passed by Atmos from the stack context | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_kubemarine_config"></a> [kubemarine\_config](#output\_kubemarine\_config) | Generated `cluster.yaml` without the local keyfile path; the dump of the last run is in `.local-runtime/kubemarine/<environment>` |
<!-- END_TF_DOCS -->
