output "endpoint_ids" {
  description = "IDs of the endpoints by service key"
  value       = merge({ for k, e in aws_vpc_endpoint.interface : k => e.id }, { for k, e in aws_vpc_endpoint.gateway : k => e.id })
}

output "security_group_id" {
  description = "Security group of the interface endpoints, null without them"
  value       = try(aws_security_group.endpoints[0].id, null)
}
