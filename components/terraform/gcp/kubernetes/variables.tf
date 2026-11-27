variable "cloud" {
  description = "Cloud identifier, passed by Atmos from the stack context"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name; the names of the created resources start with it"
  type        = string
}
variable "region" {
  description = "Google Cloud region of the resources"
  type        = string
}
variable "project_id" {
  description = "Google Cloud project of the cluster"
  type        = string
}

variable "location" {
  description = "Region or zone of the cluster"
  type        = string
}
variable "vpc_id" {
  description = "ID of the VPC network of the cluster"
  type        = string
}
variable "subnet_id" {
  description = "ID of the subnet of the cluster; its secondary ranges `pods` and `services` are used"
  type        = string
}
variable "admin_cidrs" {
  description = "CIDR blocks allowed to reach the Kubernetes API (master authorized networks); at least one"
  type        = list(string)
  validation {
    condition     = length(var.admin_cidrs) > 0 && alltrue([for c in var.admin_cidrs : can(cidrhost(c, 0))])
    error_message = "Supply at least one valid operator CIDR for Kubernetes API access."
  }
}
variable "node_count" {
  description = "Number of nodes of the node pool"
  type        = number
  default     = 2
}
variable "machine_type" {
  description = "Compute Engine machine type of the nodes"
  type        = string
  default     = "e2-standard-2"
}
variable "disk_size_gb" {
  description = "Boot disk size of the nodes, GB"
  type        = number
  default     = 50
}
variable "deletion_protection" {
  description = "Protect the cluster from deletion; set false before a destroy"
  type        = bool
  default     = true
}

variable "tenant" {
  description = "Customer identifier, passed by Atmos from the stack context"
  type        = string
  default     = null
}

variable "stage" {
  description = "Stage name, passed by Atmos from the stack context"
  type        = string
  default     = null
}
