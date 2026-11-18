# Representative inputs for `task lint:trivy` (trivy config --tf-vars): without them for_each drops every VM.
# Same values as the variables block of outputs.tftest.hcl.
environment    = "t-s"
region         = "europe-west3"
project_id     = "p"
name           = "nodes"
location       = "europe-west3-a"
vpc_id         = "projects/p/global/networks/vpc"
subnet_ids     = { main = "projects/p/regions/europe-west3/subnetworks/main" }
ssh_public_key = "ssh-ed25519 AAAA"
allowed_cidrs  = ["10.0.0.0/16"]
vms = {
  cp-1 = { roles = ["control-plane", "worker"], instance_type = "e2-standard-4", subnet = "main" }
}
