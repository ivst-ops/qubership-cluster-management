# azure/network

Creates the resource group, the VNet and the subnets of an Azure stack.

## Notes

- A subnet with `public: false` has default outbound access turned off for VMs without a public IP.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

None declared in the stack catalog.

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
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; the names of the created resources start with it | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Azure region of the resources | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | VNet subnets by key; `public = false` turns off default outbound Internet access for VMs without a public IP | <pre>map(object({<br/>    cidr_block = string<br/>    public     = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | IPv4 address range of the VNet | `string` | n/a | yes |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_cost_tags"></a> [cost\_tags](#input\_cost\_tags) | Extra cost-allocation tags, for example `{ cost-center = "cc-1234", owner = "team-x" }`; the mandatory tags (`tenant`, `stage`, `environment`, `cloud`, `managed-by`) win over keys of the same name | `map(string)` | `{}` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, passed by Atmos from the stack context | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the created resource group |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | IDs of the subnets, by subnet key |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | IPv4 address range of the VNet |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VNet |
<!-- END_TF_DOCS -->
