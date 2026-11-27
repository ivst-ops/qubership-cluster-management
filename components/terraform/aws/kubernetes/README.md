# aws/kubernetes

Creates an EKS cluster with secrets encrypted by a customer-managed KMS key, access entries, managed add-ons, IAM roles for service accounts and managed node groups.

## Notes

- The API endpoint is private unless `public_access_cidrs` lists CIDR blocks.
- Access goes through EKS access entries (`authentication_mode: API`). An existing cluster in `CONFIG_MAP` mode moves one step per apply: set `authentication_mode: API_AND_CONFIG_MAP`, apply, then remove it and apply again.
- The IAM user with static keys exists only in the local lab (`local_endpoint` set); real stacks name their operator and runner roles in `access_entries`.
- Node groups take `node_group_defaults` from the stack catalog. Update and repair settings have safe defaults (one node at a time, no forced update, no automatic repair) and are overridden per group or per stack.
- Add-ons marked `before_nodes` are installed with the cluster; the others wait for the node groups.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| `kubernetes` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/aws/kubernetes.yaml` |

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_addons"></a> [addons](#module\_addons) | ../../../../providers/aws/modules/eks-addons | n/a |
| <a name="module_addons_before_nodes"></a> [addons\_before\_nodes](#module\_addons\_before\_nodes) | ../../../../providers/aws/modules/eks-addons | n/a |
| <a name="module_irsa"></a> [irsa](#module\_irsa) | ../../../../providers/aws/modules/eks-irsa | n/a |
| <a name="module_node_groups"></a> [node\_groups](#module\_node\_groups) | ../../../../providers/aws/modules/eks-node-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_eks_access_entry.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cluster_secrets_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user.kubectl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_kms_alias.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; the names of the created resources start with it | `string` | n/a | yes |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, passed by Atmos from the stack context | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | IDs of the subnets, by subnet key | `map(string)` | n/a | yes |
| <a name="input_access_entries"></a> [access\_entries](#input\_access\_entries) | IAM principals allowed to use the Kubernetes API (operators, runners), with an EKS access policy for the whole cluster | <pre>map(object({<br/>    principal_arn = string<br/>    policy_arn    = optional(string, "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy")<br/>  }))</pre> | `{}` | no |
| <a name="input_addons"></a> [addons](#input\_addons) | EKS managed add-ons by name. `before_nodes`: installed with the cluster (CNI, kube-proxy), otherwise after the node groups. `irsa_role`: a key of `irsa_roles` | <pre>map(object({<br/>    version                     = optional(string)<br/>    configuration_values        = optional(any, {})<br/>    resolve_conflicts_on_update = optional(string, "OVERWRITE")<br/>    preserve                    = optional(bool, true)<br/>    before_nodes                = optional(bool, false)<br/>    irsa_role                   = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_authentication_mode"></a> [authentication\_mode](#input\_authentication\_mode) | EKS authentication mode: API (access entries only, the default) or API\_AND\_CONFIG\_MAP while moving an older cluster | `string` | `"API"` | no |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_cost_tags"></a> [cost\_tags](#input\_cost\_tags) | Extra cost-allocation tags, for example `{ cost-center = "cc-1234", owner = "team-x" }`; the mandatory tags (`tenant`, `stage`, `environment`, `cloud`, `managed-by`) win over keys of the same name | `map(string)` | `{}` | no |
| <a name="input_irsa_enabled"></a> [irsa\_enabled](#input\_irsa\_enabled) | Create the OIDC provider of the cluster and the roles of `irsa_roles` | `bool` | `false` | no |
| <a name="input_irsa_roles"></a> [irsa\_roles](#input\_irsa\_roles) | IAM roles for service accounts by short name: namespace, service account and AWS managed policies | <pre>map(object({<br/>    namespace       = string<br/>    service_account = string<br/>    policy_arns     = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes minor version of the cluster, for example `"1.34"`; null takes the EKS default | `string` | `null` | no |
| <a name="input_local_endpoint"></a> [local\_endpoint](#input\_local\_endpoint) | Floci endpoint of the local lab; null uses the real cloud APIs and the normal credential chain | `string` | `null` | no |
| <a name="input_node_group_defaults"></a> [node\_group\_defaults](#input\_node\_group\_defaults) | Settings every node group takes unless it sets its own (stack catalog) | <pre>object({<br/>    instance_type    = optional(string, "m6i.xlarge")<br/>    min_size         = optional(number, 3)<br/>    max_size         = optional(number, 3)<br/>    desired_size     = optional(number, 3)<br/>    capacity_type    = optional(string, "ON_DEMAND")<br/>    root_volume_size = optional(number, 50)<br/>    # Update and repair: safe defaults (one node at a time, no forced update, no automatic repair), overridden in the<br/>    # stack. max_unavailable_percentage replaces max_unavailable when set.<br/>    max_unavailable            = optional(number, 1)<br/>    max_unavailable_percentage = optional(number)<br/>    force_update_version       = optional(bool, false)<br/>    auto_repair                = optional(bool, false)<br/>    # AL2023 by default; Bottlerocket is also accepted. use_custom_ami: the launch template names the EKS image found by name (the<br/>    # NodeConfig is then the only one on the node); pin ami_release_version, or a new image rolls the group on apply.<br/>    ami_type            = optional(string, "AL2023_x86_64_STANDARD")<br/>    use_custom_ami      = optional(bool, true)<br/>    ami_release_version = optional(string)<br/>    max_pods            = optional(number)<br/>    kubelet_config      = optional(any, {})<br/>  })</pre> | `{}` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Managed node groups by short name. `subnets`: keys of `subnet_ids` (all when empty). `additional_volumes`: dedicated EBS volumes (for example for the container runtime and the kubelet). Empty (default): no node groups | <pre>map(object({<br/>    instance_type              = optional(string)<br/>    min_size                   = optional(number)<br/>    max_size                   = optional(number)<br/>    desired_size               = optional(number)<br/>    capacity_type              = optional(string)<br/>    root_volume_size           = optional(number)<br/>    max_unavailable            = optional(number)<br/>    max_unavailable_percentage = optional(number)<br/>    force_update_version       = optional(bool)<br/>    auto_repair                = optional(bool)<br/>    ami_type                   = optional(string)<br/>    use_custom_ami             = optional(bool)<br/>    ami_release_version        = optional(string)<br/>    max_pods                   = optional(number)<br/>    kubelet_config             = optional(any)<br/>    subnets                    = optional(list(string), [])<br/>    labels                     = optional(map(string), {})<br/>    taints = optional(list(object({<br/>      key    = string<br/>      value  = optional(string)<br/>      effect = string<br/>    })), [])<br/>    additional_volumes = optional(list(object({<br/>      block_device_name     = string<br/>      volume_size           = number<br/>      volume_type           = optional(string, "gp3")<br/>      iops                  = optional(number, 3000)<br/>      throughput            = optional(number, 125)<br/>      delete_on_termination = optional(bool, true)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_public_access_cidrs"></a> [public\_access\_cidrs](#input\_public\_access\_cidrs) | CIDR blocks allowed to reach the public Kubernetes API endpoint. Empty (default): no public endpoint, the API is reachable from inside the VPC only. The lab stacks set 0.0.0.0/0 | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region of the resources | `string` | `"us-east-1"` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | Service CIDR for the node user data when the cluster does not report one (EKS always does; tests set it) | `string` | `null` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, passed by Atmos from the stack context | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_addon_versions"></a> [addon\_versions](#output\_addon\_versions) | Installed version of each managed add-on |
| <a name="output_cluster_ca_data"></a> [cluster\_ca\_data](#output\_cluster\_ca\_data) | Certificate authority data of the cluster, base64 |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Kubernetes API endpoint of the cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the EKS cluster |
| <a name="output_node_group_names"></a> [node\_group\_names](#output\_node\_group\_names) | Names of the managed node groups by short name |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | OIDC provider of the cluster, null without IRSA |
<!-- END_TF_DOCS -->
