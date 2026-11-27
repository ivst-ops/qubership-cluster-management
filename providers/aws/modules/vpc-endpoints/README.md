# vpc-endpoints

Creates the VPC endpoints through which nodes in a private network reach AWS APIs without Internet access: interface endpoints behind one security group that allows HTTPS from the VPC, and gateway endpoints as routes.

## Notes

- Used by `aws/network`, which passes its `vpc_endpoints` variable as `endpoints`.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

None. This is a child module; the calling component passes every input.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_security_group.endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_security_group_ingress_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Prefix of the resource names, usually the environment | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region; service names default to `com.amazonaws.<region>.<key>` | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | IPv4 range allowed to reach the interface endpoints over HTTPS | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC of the endpoints | `string` | n/a | yes |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | Endpoints by service key (`ecr.api`, `ecr.dkr`, `s3`, `sts`, `ec2`, ...). `service_name` overrides `com.amazonaws.<region>.<key>` | <pre>map(object({<br/>    type                = optional(string, "Interface")<br/>    service_name        = optional(string)<br/>    private_dns_enabled = optional(bool, true)<br/>    policy              = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_route_table_ids"></a> [route\_table\_ids](#input\_route\_table\_ids) | Route tables that get the routes of the gateway endpoints | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnets of the interface endpoints (one per availability zone) | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags of the endpoints and the security group (the provider adds the cost tags) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_endpoint_ids"></a> [endpoint\_ids](#output\_endpoint\_ids) | IDs of the endpoints by service key |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group of the interface endpoints, null without them |
<!-- END_TF_DOCS -->
