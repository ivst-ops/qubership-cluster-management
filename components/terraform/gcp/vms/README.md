# gcp/vms

Creates a group of Compute Engine VMs with firewall rules: traffic is unrestricted inside the group, and the listed ports are open from the allowed CIDR blocks.

## Notes

- Each group is its own Atmos component and state; the Kubemarine stacks inherit one abstract VM component.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| `jump-host` | `vars.vpc_id` | `network` (`.vpc_id`) | `stacks/catalog/kubemarine/gcp-vms.yaml` |
| `jump-host` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/kubemarine/gcp-vms.yaml` |
| `nexus` | `vars.vpc_id` | `network` (`.vpc_id`) | `stacks/catalog/kubemarine/gcp-vms.yaml` |
| `nexus` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/kubemarine/gcp-vms.yaml` |
| `nexus` | `vars.allowed_cidrs` | `network` (`.vpc_cidr`) | `stacks/catalog/kubemarine/gcp-vms.yaml` |
| `vms` | `vars.vpc_id` | `network` (`.vpc_id`) | `stacks/catalog/kubemarine/gcp-vms.yaml` |
| `vms` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/kubemarine/gcp-vms.yaml` |
| `vms` | `vars.allowed_cidrs` | `network` (`.vpc_cidr`) | `stacks/catalog/kubemarine/gcp-vms.yaml` |

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_firewall.internal](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.ports](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_instance.vm](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_cidrs"></a> [allowed\_cidrs](#input\_allowed\_cidrs) | Sources for ports: the subnet CIDR for private groups, operator CIDRs for the jump host | `list(string)` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; the names of the created resources start with it | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Zone for the VMs | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Group name: resource name prefix and network tag | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project of the VMs | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Google Cloud region of the resources | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Public half of the SOPS-stored key (TF\_VAR\_ssh\_public\_key from sops exec-env) | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | IDs of the subnets, by subnet key | `map(string)` | n/a | yes |
| <a name="input_vms"></a> [vms](#input\_vms) | VMs by name; roles are Kubemarine roles or empty; `instance_type` is the machine type | <pre>map(object({<br/>    roles         = optional(list(string), [])<br/>    instance_type = string<br/>    subnet        = string<br/>    volume_size   = optional(number, 50)<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC network of the VMs | `string` | n/a | yes |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_cost_tags"></a> [cost\_tags](#input\_cost\_tags) | Extra cost-allocation tags, for example `{ cost-center = "cc-1234", owner = "team-x" }`; the mandatory tags (`tenant`, `stage`, `environment`, `cloud`, `managed-by`) win over keys of the same name | `map(string)` | `{}` | no |
| <a name="input_image"></a> [image](#input\_image) | Boot image of the VMs, as project/image or project/family | `string` | `"ubuntu-os-cloud/ubuntu-2404-lts-amd64"` | no |
| <a name="input_ports"></a> [ports](#input\_ports) | TCP ports open to `allowed_cidrs` | `list(number)` | <pre>[<br/>  22<br/>]</pre> | no |
| <a name="input_public"></a> [public](#input\_public) | Give the VMs external IPs | `bool` | `false` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, passed by Atmos from the stack context | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_vms"></a> [vms](#output\_vms) | The created VMs: name, roles, address (public or private, by `public`) and internal address |
<!-- END_TF_DOCS -->
