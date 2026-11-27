output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}
output "vpc_id" {
  description = "ID of the VNet"
  value       = azurerm_virtual_network.main.id
}
output "vpc_cidr" {
  description = "IPv4 address range of the VNet"
  value       = var.vpc_cidr
}
output "subnet_ids" {
  description = "IDs of the subnets, by subnet key"
  value       = { for k, v in azurerm_subnet.main : k => v.id }
}
