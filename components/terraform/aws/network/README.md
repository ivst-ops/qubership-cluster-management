# aws/network

Creates the VPC of an AWS stack: subnets in the given availability zones, an Internet gateway with a route table for the public subnets, and the optional VPC endpoints of the private-network profile.

## Notes

- A subnet with `public: false` gets no Internet route; an isolated installation then reaches only the VPC.
- `stacks/catalog/aws/private-network.yaml` lists the VPC endpoints of a stack without Internet access.
- Other AWS components read `vpc_id` and `subnet_ids` from its state, so it is created first and deleted last.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

None declared in the stack catalog.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | ../../../../providers/aws/modules/vpc-endpoints | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; the names of the created resources start with it | `string` | n/a | yes |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, passed by Atmos from the stack context | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | VPC subnets | <pre>map(object({<br/>    cidr_block        = string<br/>    availability_zone = string<br/>    public            = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | IPv4 address range for the VPC | `string` | n/a | yes |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_cost_tags"></a> [cost\_tags](#input\_cost\_tags) | Extra cost-allocation tags, for example `{ cost-center = "cc-1234", owner = "team-x" }`; the mandatory tags (`tenant`, `stage`, `environment`, `cloud`, `managed-by`) win over keys of the same name | `map(string)` | `{}` | no |
| <a name="input_local_endpoint"></a> [local\_endpoint](#input\_local\_endpoint) | Floci endpoint of the local lab; null uses the real cloud APIs and the normal credential chain | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region of the resources | `string` | `"us-east-1"` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | VPC endpoints of the private-network profile by service key, for example `{ "ecr.api" = {}, s3 = { type = "Gateway" } }`; empty (default): none | <pre>map(object({<br/>    type                = optional(string, "Interface")<br/>    service_name        = optional(string)<br/>    private_dns_enabled = optional(bool, true)<br/>    policy              = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | IDs of the subnets, by subnet key |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | IPv4 address range of the VPC |
| <a name="output_vpc_endpoint_ids"></a> [vpc\_endpoint\_ids](#output\_vpc\_endpoint\_ids) | IDs of the VPC endpoints by service key |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the created VPC |
<!-- END_TF_DOCS -->
