# eks-userdata

Renders the user data of an EKS node: for AL2023 a multipart document with the CA bundles and a NodeConfig with the kubelet settings, for Bottlerocket the TOML settings.

## Notes

- Used by `eks-node-group`.
- With `is_custom_ami = true` the NodeConfig also carries the cluster connection and the service CIDR.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

None. This is a child module; the calling component passes every input.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS cluster name | `string` | n/a | yes |
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | EKS AMI type of the node group; selects the user-data format (AL2023 NodeConfig or Bottlerocket TOML). CUSTOM: own AL2023-based image | `string` | `"AL2023_x86_64_STANDARD"` | no |
| <a name="input_bootstrap_labels"></a> [bootstrap\_labels](#input\_bootstrap\_labels) | Node labels, Bottlerocket with `is_custom_ami = true` only (managed node groups set labels themselves) | `map(string)` | `{}` | no |
| <a name="input_bottlerocket_settings"></a> [bottlerocket\_settings](#input\_bottlerocket\_settings) | Extra Bottlerocket TOML lines, for example settings.kernel.sysctl entries | `list(string)` | `[]` | no |
| <a name="input_ca_bundles"></a> [ca\_bundles](#input\_ca\_bundles) | PEM bundles added to the trust store of the nodes (contents, not paths) | `list(string)` | `[]` | no |
| <a name="input_cluster_auth_base64"></a> [cluster\_auth\_base64](#input\_cluster\_auth\_base64) | Certificate authority data of the cluster, base64 (only with `is_custom_ami = true`) | `string` | `null` | no |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Kubernetes API endpoint of the cluster (only with `is_custom_ami = true`) | `string` | `null` | no |
| <a name="input_is_custom_ami"></a> [is\_custom\_ami](#input\_is\_custom\_ami) | The launch template names the image: the user data then carries the cluster connection, which EKS does not add | `bool` | `false` | no |
| <a name="input_kubelet_extra_args"></a> [kubelet\_extra\_args](#input\_kubelet\_extra\_args) | Extra kubelet flags | `list(string)` | `[]` | no |
| <a name="input_kubelet_extra_config"></a> [kubelet\_extra\_config](#input\_kubelet\_extra\_config) | KubeletConfiguration fields of the NodeConfig (reservations, eviction) | `any` | `{}` | no |
| <a name="input_max_pods"></a> [max\_pods](#input\_max\_pods) | kubelet maxPods; null keeps the value of the image (the stack sets it per instance type) | `number` | `null` | no |
| <a name="input_post_userdata"></a> [post\_userdata](#input\_post\_userdata) | MIME part placed after the NodeConfig part (AL2023) | `string` | `null` | no |
| <a name="input_pre_userdata"></a> [pre\_userdata](#input\_pre\_userdata) | MIME parts placed before the CA and NodeConfig parts (AL2023) | `list(string)` | `[]` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | Service CIDR of the cluster (`kubernetes_network_config.service_ipv4_cidr` of the cluster); required with `is_custom_ami = true` | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_nodeconfig"></a> [nodeconfig](#output\_nodeconfig) | NodeConfig written into the AL2023 user data, null when there is none (for tests and reviews) |
| <a name="output_userdata"></a> [userdata](#output\_userdata) | User data of the launch template, base64 |
| <a name="output_userdata_decoded"></a> [userdata\_decoded](#output\_userdata\_decoded) | User data of the launch template, plain text |
<!-- END_TF_DOCS -->
