output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}
output "cluster_id" {
  description = "Azure resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}
output "resource_group_name" {
  description = "Resource group of the AKS cluster"
  value       = var.resource_group_name
}
output "cluster_endpoint" {
  description = "Kubernetes API endpoint of the cluster"
  # Floci currently labels user credentials as clusterAdmin, so the provider may omit kube_config.
  value     = try(azurerm_kubernetes_cluster.main.kube_config[0].host, "https://${azurerm_kubernetes_cluster.main.fqdn}")
  sensitive = true
}
