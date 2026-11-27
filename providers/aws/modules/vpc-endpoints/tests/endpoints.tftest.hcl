mock_provider "aws" {}

variables {
  name            = "t-s"
  region          = "eu-west-1"
  vpc_id          = "vpc-0"
  vpc_cidr        = "10.40.0.0/16"
  subnet_ids      = ["subnet-a", "subnet-b"]
  route_table_ids = ["rtb-0"]
  endpoints = {
    "ecr.api" = {}
    "ecr.dkr" = {}
    sts       = {}
    s3        = { type = "Gateway" }
  }
}

run "interface_and_gateway" {
  command = plan
  assert {
    condition     = aws_vpc_endpoint.interface["ecr.dkr"].service_name == "com.amazonaws.eu-west-1.ecr.dkr"
    error_message = "service name is not derived from the region and key"
  }
  assert {
    condition     = length(aws_vpc_endpoint.interface) == 3 && length(aws_vpc_endpoint.gateway) == 1
    error_message = "three interface and one gateway endpoint expected"
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.https[0].cidr_ipv4 == "10.40.0.0/16" && aws_vpc_security_group_ingress_rule.https[0].from_port == 443
    error_message = "interface endpoints must accept HTTPS from the VPC only"
  }
}

run "nothing_by_default" {
  command = plan
  variables {
    endpoints = {}
  }
  assert {
    condition     = length(aws_security_group.endpoints) == 0 && length(aws_vpc_endpoint.interface) == 0
    error_message = "no endpoints must create nothing"
  }
}
