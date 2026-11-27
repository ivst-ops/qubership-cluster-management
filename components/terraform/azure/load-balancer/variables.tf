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
  description = "Azure region of the resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group of the load balancer"
  type        = string
}
variable "vpc_id" {
  description = "ID of the VNet of the backend addresses"
  type        = string
}
variable "backend_addresses" {
  description = "Stable private backend addresses; AKS-managed pools are not discovered automatically"
  type        = map(string)
  validation {
    condition     = length(var.backend_addresses) > 0
    error_message = "At least one backend address must be supplied."
  }
}
variable "frontend_port" {
  description = "TCP port of the load balancer frontend"
  type        = number
  default     = 80
}
variable "backend_port" {
  description = "TCP port of the backend addresses"
  type        = number
  default     = 80
}
