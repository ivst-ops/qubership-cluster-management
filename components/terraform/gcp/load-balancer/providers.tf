provider "google" {
  project = var.project_id
  region  = var.region

  # FinOps cost-allocation labels on every resource that has labels (cost_tags.tf).
  default_labels = local.cost_tags
}
