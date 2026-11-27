resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}


resource "aws_subnet" "main" {
  for_each = var.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.environment}-subnet-${each.key}"
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public"
  }
}

# Subnets with public = false get no Internet route: an isolated installation reaches only the VPC.
resource "aws_route_table_association" "public" {
  for_each = { for key, subnet in aws_subnet.main : key => subnet if var.subnets[key].public }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private-network profile: VPC endpoints for nodes without Internet access. One interface subnet per
# availability zone (an endpoint takes at most one), gateway routes in the main and the public route table.
locals {
  endpoint_subnets = {
    for az in distinct([for s in values(var.subnets) : s.availability_zone]) :
    az => [for k, s in var.subnets : aws_subnet.main[k].id if s.availability_zone == az][0]
  }
}

module "vpc_endpoints" {
  source = "../../../../providers/aws/modules/vpc-endpoints"

  name            = var.environment
  region          = var.region
  vpc_id          = aws_vpc.main.id
  vpc_cidr        = aws_vpc.main.cidr_block
  subnet_ids      = values(local.endpoint_subnets)
  route_table_ids = [aws_vpc.main.main_route_table_id, aws_route_table.public.id]
  endpoints       = var.vpc_endpoints
}
