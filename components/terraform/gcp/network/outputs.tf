output "vpc_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.main.id
}
output "vpc_cidr" {
  description = "Primary IPv4 range of the subnet"
  value       = google_compute_subnetwork.main.ip_cidr_range
}
output "subnet_id" {
  description = "ID of the subnet"
  value       = google_compute_subnetwork.main.id
}
output "subnet_ids" {
  description = "IDs of the subnets, by subnet key; the only key is `main`"
  value       = { main = google_compute_subnetwork.main.id }
}
