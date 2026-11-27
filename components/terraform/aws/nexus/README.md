# aws/nexus

Creates the Nexus Repository VM that serves packages, container images and charts to a stack without Internet access.

## Notes

- The VM is configured by its user data; a change of the user data replaces the VM.
- At first boot the VM downloads the Nexus archive from `download.sonatype.com`, so it needs Internet access then.
- With `nexus_wait_for_ready: true` the apply waits until Nexus reports that it accepts writes. It is false by default; the stack catalog sets it, and the destroy workflow turns it off.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| `nexus` | `vars.vpc_id` | `network` (`.vpc_id`) | `stacks/catalog/aws/nexus.yaml` |
| `nexus` | `vars.subnet_id` | `network` (`.subnet_ids.a`) | `stacks/catalog/aws/nexus.yaml` |

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | = 2.3.5 |
| <a name="requirement_http"></a> [http](#requirement\_http) | = 3.6.3 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_instance.nexus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.nexus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.nexus_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [external_external.nexus_endpoint](https://registry.terraform.io/providers/hashicorp/external/2.3.5/docs/data-sources/external) | data source |
| [http_http.nexus_ready](https://registry.terraform.io/providers/hashicorp/http/3.6.3/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | ID of the machine image of the Nexus VM | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; the names of the created resources start with it | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type of the Nexus VM | `string` | n/a | yes |
| <a name="input_nexus_version"></a> [nexus\_version](#input\_nexus\_version) | Nexus Repository version installed on the VM | `string` | n/a | yes |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, passed by Atmos from the stack context | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of the subnet of the Nexus VM | `string` | n/a | yes |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, passed by Atmos from the stack context | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC of the Nexus VM | `string` | n/a | yes |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_cost_tags"></a> [cost\_tags](#input\_cost\_tags) | Extra cost-allocation tags, for example `{ cost-center = "cc-1234", owner = "team-x" }`; the mandatory tags (`tenant`, `stage`, `environment`, `cloud`, `managed-by`) win over keys of the same name | `map(string)` | `{}` | no |
| <a name="input_local_endpoint"></a> [local\_endpoint](#input\_local\_endpoint) | Floci endpoint of the local lab; null uses the real cloud APIs and the normal credential chain | `string` | `null` | no |
| <a name="input_nexus_readiness_url"></a> [nexus\_readiness\_url](#input\_nexus\_readiness\_url) | Full Nexus writable-status endpoint URL | `string` | `null` | no |
| <a name="input_nexus_wait_for_ready"></a> [nexus\_wait\_for\_ready](#input\_nexus\_wait\_for\_ready) | Wait for Nexus readiness during OpenTofu apply | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region of the resources | `string` | `"us-east-1"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
