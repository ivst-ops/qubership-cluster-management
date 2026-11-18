# tflint settings for `task lint:tflint` (compose.lint.yml), run with --recursive over components/terraform.
# Only the bundled `terraform` ruleset: the cloud rulesets (aws, azurerm, google) are plugins that `tflint --init`
# downloads from GitHub, which the offline gate cannot do. Add them when they are mirrored.
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Every module must say what it needs: reproducible runs with pinned versions.
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = false
}

# Atmos passes the stack context (tenant, stage, cloud, environment, region, local_endpoint) to every component, so
# modules declare it even when they do not use it; readiness checks are data sources used only for their postcondition.
rule "terraform_unused_declarations" {
  enabled = false
}
