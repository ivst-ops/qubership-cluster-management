# aws/vms

Creates a group of EC2 VMs (cluster nodes, the jump host or a service VM) with a key pair and a security group. Traffic is unrestricted inside the group; the listed ports are open from the allowed CIDR blocks.

## Notes

- Each group is its own Atmos component and state; the Kubemarine stacks inherit one abstract VM component.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| `jump-host` | `vars.vpc_id` | `network` (`.vpc_id`) | `stacks/catalog/kubemarine/aws-vms.yaml` |
| `jump-host` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/kubemarine/aws-vms.yaml` |
| `nexus` | `vars.vpc_id` | `network` (`.vpc_id`) | `stacks/catalog/kubemarine/aws-vms.yaml` |
| `nexus` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/kubemarine/aws-vms.yaml` |
| `nexus` | `vars.allowed_cidrs` | `network` (`.vpc_cidr`) | `stacks/catalog/kubemarine/aws-vms.yaml` |
| `vms` | `vars.vpc_id` | `network` (`.vpc_id`) | `stacks/catalog/kubemarine/aws-vms.yaml` |
| `vms` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/kubemarine/aws-vms.yaml` |
| `vms` | `vars.allowed_cidrs` | `network` (`.vpc_cidr`) | `stacks/catalog/kubemarine/aws-vms.yaml` |

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
| [aws_instance.vm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_cidrs"></a> [allowed\_cidrs](#input\_allowed\_cidrs) | Sources for ports: the VPC CIDR for private groups, operator CIDRs for the jump host | `list(string)` | n/a | yes |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | ID of the machine image of the VMs | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; the names of the created resources start with it | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Group name: resource name prefix and the first Role tag | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Public half of the SOPS-stored key (TF\_VAR\_ssh\_public\_key from sops exec-env) | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | IDs of the subnets, by subnet key | `map(string)` | n/a | yes |
| <a name="input_vms"></a> [vms](#input\_vms) | VMs by name; roles are Kubemarine roles (balancer, control-plane, worker) or empty | <pre>map(object({<br/>    roles         = optional(list(string), [])<br/>    instance_type = string<br/>    subnet        = string<br/>    volume_size   = optional(number, 50)<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC of the VMs | `string` | n/a | yes |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_cost_tags"></a> [cost\_tags](#input\_cost\_tags) | Extra cost-allocation tags, for example `{ cost-center = "cc-1234", owner = "team-x" }`; the mandatory tags (`tenant`, `stage`, `environment`, `cloud`, `managed-by`) win over keys of the same name | `map(string)` | `{}` | no |
| <a name="input_local_endpoint"></a> [local\_endpoint](#input\_local\_endpoint) | Floci endpoint of the local lab; null uses the real cloud APIs and the normal credential chain | `string` | `null` | no |
| <a name="input_ports"></a> [ports](#input\_ports) | TCP ports open to `allowed_cidrs` | `list(number)` | <pre>[<br/>  22<br/>]</pre> | no |
| <a name="input_public"></a> [public](#input\_public) | Give the VMs public IPs; the subnet must route to the Internet | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region of the resources | `string` | `"us-east-1"` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, passed by Atmos from the stack context | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_vms"></a> [vms](#output\_vms) | The created VMs: name, roles, address (public or private, by `public`) and internal address |
<!-- END_TF_DOCS -->
