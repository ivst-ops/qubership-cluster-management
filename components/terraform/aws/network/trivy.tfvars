# Representative inputs for `task lint:trivy` (trivy config --tf-vars): without them for_each drops the subnets.
# Values as in stacks/customers/customer1/aws/staging.yaml; one public and one private subnet.
environment = "t-s"
region      = "us-east-1"
vpc_cidr    = "10.40.0.0/16"
subnets = {
  a = { cidr_block = "10.40.1.0/24", availability_zone = "us-east-1a", public = true }
  b = { cidr_block = "10.40.2.0/24", availability_zone = "us-east-1b", public = false }
}
vpc_endpoints = {
  "ecr.api" = {}
  s3        = { type = "Gateway" }
}
