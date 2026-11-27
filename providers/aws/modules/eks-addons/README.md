# eks-addons

Installs EKS managed add-ons from a map of add-on names to their settings.

## Notes

- Used by `aws/kubernetes` twice: for the add-ons installed with the cluster and for those that wait for the nodes.

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
| [aws_eks_addon.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS cluster of the add-ons | `string` | n/a | yes |
| <a name="input_addons"></a> [addons](#input\_addons) | Add-ons by EKS add-on name (vpc-cni, kube-proxy, coredns, aws-ebs-csi-driver, ...); version null takes the default of the cluster version | <pre>map(object({<br/>    version                     = optional(string)<br/>    configuration_values        = optional(any, {})<br/>    service_account_role_arn    = optional(string)<br/>    resolve_conflicts_on_update = optional(string, "OVERWRITE")<br/>    preserve                    = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags of the add-ons (the provider adds the cost tags) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_versions"></a> [versions](#output\_versions) | Installed version of each add-on |
<!-- END_TF_DOCS -->
