output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.main.name
}
output "location" {
  description = "Location (region or zone) of the GKE cluster"
  value       = google_container_cluster.main.location
}
output "cluster_endpoint" {
  description = "Kubernetes API endpoint of the cluster"
  value       = "https://${google_container_cluster.main.endpoint}"
}
output "cluster_ca_data" {
  description = "Certificate authority data of the cluster, base64"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}
