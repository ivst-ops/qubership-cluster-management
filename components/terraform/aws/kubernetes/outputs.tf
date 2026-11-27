output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_data" {
  description = "Certificate authority data in base64 format"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}
output "oidc_provider_arn" {
  description = "OIDC provider of the cluster, null without IRSA"
  value       = try(module.irsa[0].oidc_provider_arn, null)
}

output "addon_versions" {
  description = "Installed version of each managed add-on"
  value       = merge(module.addons_before_nodes.versions, module.addons.versions)
}

output "node_group_names" {
  description = "Names of the managed node groups by short name"
  value       = { for k, g in module.node_groups : k => "${var.environment}-${k}" }
}
