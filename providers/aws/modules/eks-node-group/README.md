# eks-node-group

Creates an EKS managed node group with its launch template: image, instance type, encrypted root and additional volumes, metadata options, labels, taints and scaling schedules.

## Notes

- Used by `aws/kubernetes`, which creates one instance per entry of `node_groups`.
- With `use_custom_ami: false` the launch template names no image, and EKS chooses it by `ami_type`.
- The user data comes from `eks-userdata`.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

None. This is a child module; the calling component passes every input.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_userdata"></a> [userdata](#module\_userdata) | ../eks-userdata | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_autoscaling_schedule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_ami.eks_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_default_tags.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_kms_key.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_subnets.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region of the cluster; prefixes the availability-zone letters of `mng_allowed_az` | `string` | n/a | yes |
| <a name="input_cluster_auth_b64"></a> [cluster\_auth\_b64](#input\_cluster\_auth\_b64) | Certificate authority data of the cluster, base64 (only with `use_custom_ami = true`) | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Kubernetes API endpoint of the cluster (only with `use_custom_ami = true`) | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version of the cluster; selects the EKS image by name | `string` | n/a | yes |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | ARN of the IAM role of the nodes | `string` | n/a | yes |
| <a name="input_node_group_name"></a> [node\_group\_name](#input\_node\_group\_name) | Name of the node group | `string` | n/a | yes |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | Service CIDR of the cluster (`kubernetes_network_config.service_ipv4_cidr` of the cluster) | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC of the cluster | `string` | n/a | yes |
| <a name="input_worker_security_group_id"></a> [worker\_security\_group\_id](#input\_worker\_security\_group\_id) | Security group of every node | `string` | n/a | yes |
| <a name="input_additional_ebs_volumes"></a> [additional\_ebs\_volumes](#input\_additional\_ebs\_volumes) | Additional EBS volumes of every node | <pre>list(object({<br/>    block_device_name     = string<br/>    volume_size           = number<br/>    volume_type           = optional(string, "gp3")<br/>    iops                  = optional(number, null)<br/>    throughput            = optional(number, null)<br/>    delete_on_termination = optional(bool, true)<br/>  }))</pre> | `[]` | no |
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | Security groups of the nodes in addition to `worker_security_group_id` | `list(string)` | `[]` | no |
| <a name="input_additional_userdata"></a> [additional\_userdata](#input\_additional\_userdata) | MIME part placed after the node bootstrap (AL2023 only) | `string` | `null` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | ID of an own image; null searches the EKS image by name | `string` | `null` | no |
| <a name="input_ami_owner"></a> [ami\_owner](#input\_ami\_owner) | Owner of the image named by `ami_id` | `string` | `"amazon"` | no |
| <a name="input_ami_release_version"></a> [ami\_release\_version](#input\_ami\_release\_version) | Release filter of the image search (wildcards allowed, the latest match wins), or the EKS release version without a launch-template image | `string` | `null` | no |
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | EKS AMI type: `AL2023_x86_64_STANDARD`, `AL2023_ARM_64_STANDARD`, `BOTTLEROCKET_x86_64` or `BOTTLEROCKET_ARM_64`; AL2023 by default | `string` | `"AL2023_x86_64_STANDARD"` | no |
| <a name="input_bottlerocket_settings"></a> [bottlerocket\_settings](#input\_bottlerocket\_settings) | Extra Bottlerocket TOML lines | `list(string)` | <pre>[<br/>  "settings.host-containers.control.enabled = false",<br/>  "settings.host-containers.admin.enabled = false"<br/>]</pre> | no |
| <a name="input_ca_bundles"></a> [ca\_bundles](#input\_ca\_bundles) | PEM bundles added to the trust store of the nodes (contents, not paths) | `list(string)` | `[]` | no |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | Capacity type of the nodes: `ON_DEMAND` or `SPOT` | `string` | `"ON_DEMAND"` | no |
| <a name="input_cpu_credits"></a> [cpu\_credits](#input\_cpu\_credits) | CPU credit option of burstable instances: `standard` or `unlimited` | `string` | `"standard"` | no |
| <a name="input_create_schedule"></a> [create\_schedule](#input\_create\_schedule) | Create the scaling schedules of `schedules` | `bool` | `false` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | Make the nodes EBS-optimized; null decides by instance type | `bool` | `null` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enable detailed monitoring of the nodes | `bool` | `false` | no |
| <a name="input_enable_tag_specifications"></a> [enable\_tag\_specifications](#input\_enable\_tag\_specifications) | Tag the instances, volumes and network interfaces through the launch template | `bool` | `true` | no |
| <a name="input_enclave_support"></a> [enclave\_support](#input\_enclave\_support) | Enable Nitro Enclaves on the nodes | `bool` | `false` | no |
| <a name="input_encrypted"></a> [encrypted](#input\_encrypted) | Encrypt every volume of the nodes | `bool` | `true` | no |
| <a name="input_eni_delete"></a> [eni\_delete](#input\_eni\_delete) | Delete the network interface when the instance terminates | `bool` | `true` | no |
| <a name="input_force_update_version"></a> [force\_update\_version](#input\_force\_update\_version) | Update the nodes even when a pod disruption budget blocks their drain | `bool` | `false` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type of the launch template; without a launch template use `override_instance_types` | `string` | `"t3.medium"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key of the encrypted volumes; requires `encrypted = true` | `string` | `"alias/aws/ebs"` | no |
| <a name="input_kubelet_extra_args"></a> [kubelet\_extra\_args](#input\_kubelet\_extra\_args) | Extra kubelet flags; prefer `kubelet_extra_config` | `list(string)` | `[]` | no |
| <a name="input_kubelet_extra_config"></a> [kubelet\_extra\_config](#input\_kubelet\_extra\_config) | KubeletConfiguration fields of the NodeConfig (reservations, eviction) | `any` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Kubernetes labels of the nodes, managed through the EKS API | `map(string)` | `null` | no |
| <a name="input_launch_template_name"></a> [launch\_template\_name](#input\_launch\_template\_name) | Name of the launch template; null makes OpenTofu generate a unique name | `string` | `null` | no |
| <a name="input_launch_template_placement_group"></a> [launch\_template\_placement\_group](#input\_launch\_template\_placement\_group) | Placement group of the nodes | `string` | `null` | no |
| <a name="input_launch_template_placement_tenancy"></a> [launch\_template\_placement\_tenancy](#input\_launch\_template\_placement\_tenancy) | Tenancy of the nodes: `default`, `dedicated` or `host`; only with `launch_template_placement_group` | `string` | `"default"` | no |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Version of the launch template; null takes the latest | `number` | `null` | no |
| <a name="input_max_pods"></a> [max\_pods](#input\_max\_pods) | kubelet maxPods; null keeps the value of the image (the stack sets it per instance type) | `number` | `null` | no |
| <a name="input_metadata_http_endpoint"></a> [metadata\_http\_endpoint](#input\_metadata\_http\_endpoint) | Instance metadata service: `enabled` or `disabled` | `string` | `"enabled"` | no |
| <a name="input_metadata_http_put_response_hop_limit"></a> [metadata\_http\_put\_response\_hop\_limit](#input\_metadata\_http\_put\_response\_hop\_limit) | HTTP PUT response hop limit of instance metadata requests | `number` | `2` | no |
| <a name="input_metadata_http_tokens"></a> [metadata\_http\_tokens](#input\_metadata\_http\_tokens) | Session tokens of the instance metadata service (IMDSv2): `optional` or `required` | `string` | `"required"` | no |
| <a name="input_mng_allowed_az"></a> [mng\_allowed\_az](#input\_mng\_allowed\_az) | Availability-zone letters that narrow `subnet_ids` (for example `a`, `b`); `["*"]` keeps every subnet | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_mng_desired_size"></a> [mng\_desired\_size](#input\_mng\_desired\_size) | Desired number of nodes | `number` | `0` | no |
| <a name="input_mng_max_size"></a> [mng\_max\_size](#input\_mng\_max\_size) | Maximum number of nodes | `number` | `1` | no |
| <a name="input_mng_min_size"></a> [mng\_min\_size](#input\_mng\_min\_size) | Minimum number of nodes | `number` | `0` | no |
| <a name="input_mng_tags"></a> [mng\_tags](#input\_mng\_tags) | Tags of the node group in addition to `tags` | `map(any)` | `{}` | no |
| <a name="input_node_repair_config"></a> [node\_repair\_config](#input\_node\_repair\_config) | Automatic node repair of EKS; null leaves it off | <pre>object({<br/>    enabled = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_override_instance_types"></a> [override\_instance\_types](#input\_override\_instance\_types) | Instance types of the node group without a launch template | `list(string)` | <pre>[<br/>  "t3.medium"<br/>]</pre> | no |
| <a name="input_pre_userdata"></a> [pre\_userdata](#input\_pre\_userdata) | MIME parts placed before the node bootstrap (AL2023 only) | `list(string)` | `[]` | no |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | Associate a public IP address with the network interface of the nodes | `bool` | `false` | no |
| <a name="input_root_block_device_name"></a> [root\_block\_device\_name](#input\_root\_block\_device\_name) | Device name of the root volume; null takes the one of the image | `string` | `null` | no |
| <a name="input_root_iops"></a> [root\_iops](#input\_root\_iops) | Provisioned IOPS of the root volume, for `io1`, `io2` or `gp3` | `number` | `null` | no |
| <a name="input_root_throughput"></a> [root\_throughput](#input\_root\_throughput) | Throughput of a `gp3` root volume, MiB/s (at most 1000) | `number` | `null` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size of the root volume, GiB | `number` | `50` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | Type of the root volume: `standard`, `gp2`, `gp3`, `io1`, `io2`, `sc1` or `st1` | `string` | `"gp3"` | no |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | Scaling schedules of the Auto Scaling group by name; only with `create_schedule = true` | `map(any)` | `{}` | no |
| <a name="input_source_security_group_ids"></a> [source\_security\_group\_ids](#input\_source\_security\_group\_ids) | Security groups allowed to reach the nodes over SSH (port 22), without a launch template only | `list(string)` | `[]` | no |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | Name of the EC2 key pair of the nodes; without a launch template also set `source_security_group_ids` | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | IDs of the subnets of the node group | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags of every resource of the node group; tags of the launch template override them for the Auto Scaling group | `map(string)` | `{}` | no |
| <a name="input_taint_install"></a> [taint\_install](#input\_taint\_install) | Apply `taints` to the nodes | `bool` | `false` | no |
| <a name="input_taints"></a> [taints](#input\_taints) | Kubernetes taints of the nodes (at most 50) | <pre>list(object({<br/>    key    = string<br/>    value  = optional(string, null)<br/>    effect = string<br/>  }))</pre> | `[]` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create, update and delete timeouts of the node group | <pre>object({<br/>    create = optional(string, "20m")<br/>    update = optional(string, "30m")<br/>    delete = optional(string, "20m")<br/>  })</pre> | <pre>{<br/>  "create": "20m",<br/>  "delete": "20m",<br/>  "update": "30m"<br/>}</pre> | no |
| <a name="input_update_config_max_unavailable"></a> [update\_config\_max\_unavailable](#input\_update\_config\_max\_unavailable) | Maximum number of nodes unavailable during an update | `number` | `1` | no |
| <a name="input_update_config_max_unavailable_percentage"></a> [update\_config\_max\_unavailable\_percentage](#input\_update\_config\_max\_unavailable\_percentage) | Maximum percentage of nodes unavailable during an update; replaces `update_config_max_unavailable` when set | `number` | `null` | no |
| <a name="input_use_custom_ami"></a> [use\_custom\_ami](#input\_use\_custom\_ami) | The launch template names the image (the EKS image found by name, or `ami_id`); false lets EKS choose it by `ami_type` | `bool` | `true` | no |
| <a name="input_use_launch_template"></a> [use\_launch\_template](#input\_use\_launch\_template) | Create a launch template for the node group | `bool` | `true` | no |
| <a name="input_use_name_prefix"></a> [use\_name\_prefix](#input\_use\_name\_prefix) | Use `node_group_name` as a name prefix instead of the full name | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ami_info"></a> [ami\_info](#output\_ami\_info) | The machine image found for the launch template (empty without a launch template) |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | Name of the Auto Scaling group behind the node group; null before EKS reports it |
| <a name="output_eks_ami_type"></a> [eks\_ami\_type](#output\_eks\_ami\_type) | AMI type given to EKS; null when `use_custom_ami = true` and the launch template names the image |
| <a name="output_update_settings"></a> [update\_settings](#output\_update\_settings) | Update and repair settings sent to EKS (for tests and reviews) |
<!-- END_TF_DOCS -->
