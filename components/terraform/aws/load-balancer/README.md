# aws/load-balancer

Creates the Application Load Balancer that publishes the web consoles of a stack (Argo CD, Kiali, the MinIO console and Headlamp): HTTP and HTTPS listeners, host rules and target groups that forward to the node ports of their services.

## Notes

- It reads the cluster node and the Kubernetes services, so it is applied after the applications.
- `data.aws_instance.node` needs exactly one running instance in the VPC: the node of the local lab.
- The host rules are fixed: `argocd.localhost`, `kiali.localhost`, `minio.localhost` and `headlamp.localhost`.
- Without `certificate_arn` the load balancer serves plain HTTP; with it, HTTP redirects to HTTPS.

<!-- BEGIN_TF_DOCS -->
## Component dependencies

| Instance | Declared in | Needs component (output) | Catalog file |
| --- | --- | --- | --- |
| `load-balancer` | `vars.vpc_id` | `network` (`.vpc_id`) | `stacks/catalog/aws/load-balancer.yaml` |
| `load-balancer` | `vars.subnet_ids` | `network` (`.subnet_ids`) | `stacks/catalog/aws/load-balancer.yaml` |

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.3 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lb.argocd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.argocd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.headlamp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.kiali](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.minio_console](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.argocd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.headlamp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.kiali](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.minio_console](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.argocd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.headlamp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.kiali](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.minio_console](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.argocd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.headlamp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.kiali](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.minio_console](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_instance.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [kubernetes_service_v1.argocd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service_v1) | data source |
| [kubernetes_service_v1.kiali](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service_v1) | data source |
| [kubernetes_service_v1.minio_console](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service_v1) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; the names of the created resources start with it | `string` | n/a | yes |
| <a name="input_headlamp_node_port"></a> [headlamp\_node\_port](#input\_headlamp\_node\_port) | Node port of the Headlamp service on the cluster nodes | `number` | n/a | yes |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage name, passed by Atmos from the stack context | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | IDs of the subnets, by subnet key | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC of the load balancer and its target groups | `string` | n/a | yes |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of the ACM certificate for the HTTPS listener. Set: HTTPS on port 443 (TLS 1.3/1.2 policy) and HTTP redirects to it. Null: plain HTTP only | `string` | `null` | no |
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud identifier, passed by Atmos from the stack context | `string` | `null` | no |
| <a name="input_cost_tags"></a> [cost\_tags](#input\_cost\_tags) | Extra cost-allocation tags, for example `{ cost-center = "cc-1234", owner = "team-x" }`; the mandatory tags (`tenant`, `stage`, `environment`, `cloud`, `managed-by`) win over keys of the same name | `map(string)` | `{}` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Kubeconfig for this deployment; null preserves the environment-based path | `string` | `null` | no |
| <a name="input_local_endpoint"></a> [local\_endpoint](#input\_local\_endpoint) | Floci endpoint of the local lab; null uses the real cloud APIs and the normal credential chain | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region of the resources | `string` | `"us-east-1"` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Customer identifier, passed by Atmos from the stack context | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_argocd_node_port"></a> [argocd\_node\_port](#output\_argocd\_node\_port) | Node port that the load balancer forwards to Argo CD |
| <a name="output_headlamp_node_port"></a> [headlamp\_node\_port](#output\_headlamp\_node\_port) | Node port that the load balancer forwards to Headlamp |
| <a name="output_kiali_node_port"></a> [kiali\_node\_port](#output\_kiali\_node\_port) | Node port that the load balancer forwards to Kiali |
| <a name="output_minio_console_node_port"></a> [minio\_console\_node\_port](#output\_minio\_console\_node\_port) | Node port that the load balancer forwards to the MinIO console |
<!-- END_TF_DOCS -->
