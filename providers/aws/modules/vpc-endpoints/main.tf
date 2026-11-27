# VPC endpoints of the private-network profile: the nodes reach the AWS APIs without Internet access.
# Interface endpoints sit in the given subnets behind one security group that allows HTTPS from the VPC; gateway
# endpoints (S3, DynamoDB) are routes in the given route tables.
locals {
  interface = { for k, e in var.endpoints : k => e if e.type == "Interface" }
  gateway   = { for k, e in var.endpoints : k => e if e.type == "Gateway" }
}

resource "aws_security_group" "endpoints" {
  count = length(local.interface) > 0 ? 1 : 0

  name        = "${var.name}-vpce"
  description = "Interface VPC endpoints of ${var.name}: HTTPS from the VPC"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-vpce" })
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  count = length(local.interface) > 0 ? 1 : 0

  security_group_id = aws_security_group.endpoints[0].id
  description       = "HTTPS from the VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface

  vpc_id              = var.vpc_id
  service_name        = coalesce(each.value.service_name, "com.amazonaws.${var.region}.${each.key}")
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = each.value.private_dns_enabled
  policy              = each.value.policy
  tags                = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = local.gateway

  vpc_id            = var.vpc_id
  service_name      = coalesce(each.value.service_name, "com.amazonaws.${var.region}.${each.key}")
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids
  policy            = each.value.policy
  tags              = merge(var.tags, { Name = "${var.name}-${each.key}" })
}
