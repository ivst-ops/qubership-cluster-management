provider "aws" {
  region     = var.region
  access_key = var.local_endpoint != null ? "test" : null
  secret_key = var.local_endpoint != null ? "test" : null

  skip_credentials_validation = var.local_endpoint != null
  skip_metadata_api_check     = var.local_endpoint != null
  skip_requesting_account_id  = var.local_endpoint != null

  # FinOps cost-allocation tags on every resource (cost_tags.tf).
  default_tags {
    tags = local.cost_tags
  }

  endpoints {
    eks = var.local_endpoint
    iam = var.local_endpoint
    kms = var.local_endpoint
  }
}