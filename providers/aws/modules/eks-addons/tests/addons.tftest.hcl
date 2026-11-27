mock_provider "aws" {}

variables {
  cluster_name = "t-s-eks"
  addons = {
    vpc-cni = { configuration_values = { env = { ENABLE_PREFIX_DELEGATION = "true" } } }
    coredns = {}
  }
}

run "configuration_is_json" {
  command = plan
  assert {
    condition     = jsondecode(aws_eks_addon.this["vpc-cni"].configuration_values).env.ENABLE_PREFIX_DELEGATION == "true"
    error_message = "configuration values are not passed as JSON"
  }
  assert {
    condition     = aws_eks_addon.this["coredns"].resolve_conflicts_on_create == "OVERWRITE"
    error_message = "conflicts on create must be overwritten"
  }
}
