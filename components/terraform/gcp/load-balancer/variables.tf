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
  description = "Google Cloud project of the load balancer"
  type        = string
}

variable "backend_instances" {
  description = "Self-links of backend VMs; manage ingress and health-check firewall rules for these VMs separately"
  type        = list(string)
  validation {
    condition     = length(var.backend_instances) > 0
    error_message = "At least one backend VM self-link must be supplied."
  }
}
variable "port_range" {
  description = "Port or port range of the forwarding rule"
  type        = string
  default     = "80"
}
variable "health_check_port" {
  description = "Port of the HTTP health check of the backend VMs"
  type        = number
  default     = 80
}
variable "health_check_path" {
  description = "Request path of the HTTP health check"
  type        = string
  default     = "/"
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
