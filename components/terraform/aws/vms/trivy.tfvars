# Representative inputs for `task lint:trivy` (trivy config --tf-vars): without them for_each drops every VM.
# Same values as the variables block of outputs.tftest.hcl.
environment    = "t-s"
name           = "nodes"
vpc_id         = "vpc-1"
subnet_ids     = { a = "subnet-a" }
ami_id         = "ami-1"
ssh_public_key = "ssh-ed25519 AAAA"
ports          = [22, 6443]
allowed_cidrs  = ["10.0.0.0/16"]
vms = {
  cp-1 = { roles = ["control-plane", "worker"], instance_type = "m5.large", subnet = "a" }
}
