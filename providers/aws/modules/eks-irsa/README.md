# eks-irsa

Creates the OIDC provider of an EKS cluster and one IAM role per service account, with AWS managed policies.

## Notes

- Used by `aws/kubernetes` when `irsa_enabled: true`.

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
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS cluster; prefix of the role names | `string` | n/a | yes |
| <a name="input_oidc_issuer_url"></a> [oidc\_issuer\_url](#input\_oidc\_issuer\_url) | OIDC issuer of the cluster (`aws_eks_cluster.identity`[0].oidc[0].issuer) | `string` | n/a | yes |
| <a name="input_roles"></a> [roles](#input\_roles) | Roles by short name: the service account that may assume it and the managed policies it gets | <pre>map(object({<br/>    namespace       = string<br/>    service_account = string<br/>    policy_arns     = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags of the provider and the roles (the provider adds the cost tags) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the OIDC provider of the cluster |
| <a name="output_role_arns"></a> [role\_arns](#output\_role\_arns) | Role ARNs by short name |
<!-- END_TF_DOCS -->
