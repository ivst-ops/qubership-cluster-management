# Representative inputs for `task lint:trivy` (trivy config --tf-vars): without them for_each drops every VM.
# Same values as the variables block of outputs.tftest.hcl.
environment         = "t-s"
region              = "northeurope"
name                = "nodes"
resource_group_name = "rg"
subnet_ids          = { a = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/a" }
ssh_public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICeTO2fHfUH3mH3AHcLdWKcWLFOtDcaTzcZE0SEVNmPm test"
allowed_cidrs       = ["10.0.0.0/16"]
vms = {
  cp-1 = { roles = ["control-plane", "worker"], instance_type = "Standard_D4s_v5", subnet = "a" }
}
