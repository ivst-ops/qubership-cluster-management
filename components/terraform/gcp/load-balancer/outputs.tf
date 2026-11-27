output "ip_address" {
  description = "External IP address of the load balancer"
  value       = google_compute_address.main.address
}
output "load_balancer_id" {
  description = "ID of the forwarding rule"
  value       = google_compute_forwarding_rule.main.id
}
