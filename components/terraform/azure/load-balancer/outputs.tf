output "load_balancer_id" {
  description = "Azure resource ID of the load balancer"
  value       = azurerm_lb.main.id
}
output "ip_address" {
  description = "Public IP address of the load balancer frontend"
  value       = azurerm_public_ip.main.ip_address
}
