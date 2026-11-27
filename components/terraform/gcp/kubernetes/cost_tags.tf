# FinOps cost-allocation tags (docs/quality-gate.md): every cloud resource of the stack carries them.
# AWS applies them through the provider's default_tags, GCP through default_labels, Azure through `tags` on each
# resource. The same file is in every cloud module; keep the copies identical.
# Keys and values follow the strictest provider (GCP labels), so one stack tags the same way on every cloud.

variable "cost_tags" {
  description = "Extra cost-allocation tags, for example `{ cost-center = \"cc-1234\", owner = \"team-x\" }`; the mandatory tags (`tenant`, `stage`, `environment`, `cloud`, `managed-by`) win over keys of the same name"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.cost_tags : can(regex("^[a-z][a-z0-9_-]{0,62}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))
    ])
    error_message = "cost_tags: keys must match ^[a-z][a-z0-9_-]{0,62}$ and values ^[a-z0-9_-]{0,63}$ (GCP label rules, valid on every provider)."
  }
}

locals {
  # Atmos passes tenant, stage, environment and cloud to every component (stack name_template). Values are made
  # label-safe (lowercase, other characters to '-', 63 at most); a var that is not set (null) is left out.
  cost_tags_mandatory = {
    tenant      = var.tenant
    stage       = var.stage
    environment = var.environment
    cloud       = var.cloud
    managed-by  = "qubership-cluster-management"
  }
  cost_tags = merge(var.cost_tags, {
    for k, v in local.cost_tags_mandatory : k => substr(replace(lower(v), "/[^a-z0-9_-]/", "-"), 0, 63) if v != null
  })
}
