variable "kubeconfig_path" {
  description = "Path to the kubeconfig used to access the existing cluster"
  type        = string
}

# Deployment context inherited from the Atmos stack.
variable "cloud" {
  description = "Cloud identifier, not used by this component, accepted for a uniform stack context"
  type        = string
  default     = null
}

variable "tenant" {
  description = "Customer identifier, not used by this component, accepted for a uniform stack context"
  type        = string
  default     = null
}

variable "stage" {
  description = "Stage name, not used by this component, accepted for a uniform stack context"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name, not used by this component, accepted for a uniform stack context"
  type        = string
  default     = null
}

variable "region" {
  description = "Region of the cloud, not used by this component, accepted for a uniform stack context"
  type        = string
  default     = null
}

variable "local_endpoint" {
  description = "Floci endpoint of the local lab, not used by this component, accepted for a uniform stack context"
  type        = string
  default     = null
}