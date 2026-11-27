output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "IPv4 address range of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "subnet_ids" {
  description = "IDs of the subnets, by subnet key"

  value = {
    for key, subnet in aws_subnet.main :
    key => subnet.id
  }
}
output "vpc_endpoint_ids" {
  description = "IDs of the VPC endpoints by service key"
  value       = module.vpc_endpoints.endpoint_ids
}
