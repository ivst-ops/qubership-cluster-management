# kubernetes/ingress-wait

Creates an Ingress for the nginx example and waits until the ingress controller assigns it a load-balancer address. It is an example of a readiness wait in a stack.

## Notes

- It needs `kubernetes/nginx` (the Service it routes to) and the `traefik` component (its ingress class).

<!-- BEGIN_TF_DOCS -->
## Component dependencies

None declared in the stack catalog.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.3 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [kubernetes_ingress_v1.nginx](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ingress_class_name"></a> [ingress\_class\_name](#input\_ingress\_class\_name) | IngressClass handled by the installed ingress controller | `string` | n/a | yes |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Path to the kubeconfig used to access the existing cluster | `string` | n/a | yes |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, not used by this component, accepted for a uniform stack context | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, not used by this component, accepted for a uniform stack context | `string` | `null` | no |
| <a name="input_local_endpoint"></a> [local\_endpoint](#input\_local\_endpoint) | Floci endpoint of the local lab, not used by this component, accepted for a uniform stack context | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region of the cloud, not used by this component, accepted for a uniform stack context | `string` | `null` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, not used by this component, accepted for a uniform stack context | `string` | `null` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, not used by this component, accepted for a uniform stack context | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
