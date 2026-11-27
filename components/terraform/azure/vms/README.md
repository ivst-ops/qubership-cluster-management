# azure/vms

Creates a group of Linux VMs with network interfaces, a network security group and optional public IP addresses. Traffic is unrestricted inside the group; the listed ports are open from the allowed CIDR blocks.

## Notes

- Each group is its own Atmos component and state; the Kubemarine stacks inherit one abstract VM component.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| `jump-host` | `vars.resource_group_name` | `network` (`.resource_group_name`) | `stacks/catalog/kubemarine/azure-vms.yaml` |
| `jump-host` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/kubemarine/azure-vms.yaml` |
| `nexus` | `vars.resource_group_name` | `network` (`.resource_group_name`) | `stacks/catalog/kubemarine/azure-vms.yaml` |
| `nexus` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/kubemarine/azure-vms.yaml` |
| `nexus` | `vars.allowed_cidrs` | `network` (`.vpc_cidr`) | `stacks/catalog/kubemarine/azure-vms.yaml` |
| `vms` | `vars.resource_group_name` | `network` (`.resource_group_name`) | `stacks/catalog/kubemarine/azure-vms.yaml` |
| `vms` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/kubemarine/azure-vms.yaml` |
| `vms` | `vars.allowed_cidrs` | `network` (`.vpc_cidr`) | `stacks/catalog/kubemarine/azure-vms.yaml` |

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_linux_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_cidrs"></a> [allowed\_cidrs](#input\_allowed\_cidrs) | Sources for ports: the VNet CIDR for private groups, operator CIDRs for the jump host | `list(string)` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; the names of the created resources start with it | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Group name: resource name prefix and the first Role tag | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Azure region of the resources | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group of the VMs | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Public half of the SOPS-stored key (TF\_VAR\_ssh\_public\_key from sops exec-env) | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | IDs of the subnets, by subnet key | `map(string)` | n/a | yes |
| <a name="input_vms"></a> [vms](#input\_vms) | VMs by name; roles are Kubemarine roles or empty; `instance_type` is the VM size | <pre>map(object({<br/>    roles         = optional(list(string), [])<br/>    instance_type = string<br/>    subnet        = string<br/>    volume_size   = optional(number, 50)<br/>  }))</pre> | n/a | yes |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_cost_tags"></a> [cost\_tags](#input\_cost\_tags) | Extra cost-allocation tags, for example `{ cost-center = "cc-1234", owner = "team-x" }`; the mandatory tags (`tenant`, `stage`, `environment`, `cloud`, `managed-by`) win over keys of the same name | `map(string)` | `{}` | no |
| <a name="input_image"></a> [image](#input\_image) | Marketplace image of the VMs: publisher, offer, SKU and version | `object({ publisher = string, offer = string, sku = string, version = string })` | <pre>{<br/>  "offer": "ubuntu-24_04-lts",<br/>  "publisher": "Canonical",<br/>  "sku": "server",<br/>  "version": "latest"<br/>}</pre> | no |
| <a name="input_ports"></a> [ports](#input\_ports) | TCP ports open to `allowed_cidrs` | `list(number)` | <pre>[<br/>  22<br/>]</pre> | no |
| <a name="input_public"></a> [public](#input\_public) | Give the VMs public IPs | `bool` | `false` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, passed by Atmos from the stack context | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_vms"></a> [vms](#output\_vms) | The created VMs: name, roles, address (public or private, by `public`) and internal address |
<!-- END_TF_DOCS -->
