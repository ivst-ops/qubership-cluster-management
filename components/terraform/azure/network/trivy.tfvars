# Representative inputs for `task lint:trivy` (trivy config --tf-vars): without them for_each drops the subnets.
environment = "t-s"
region      = "northeurope"
vpc_cidr    = "10.50.0.0/16"
subnets = {
  public     = { cidr_block = "10.50.1.0/24", public = true }
  kubernetes = { cidr_block = "10.50.2.0/24", public = false }
}
