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
  description = "Resource group of the cluster and its identity"
  type        = string
}
variable "subnet_id" {
  description = "ID of the subnet of the default node pool"
  type        = string
}
variable "manage_network_role_assignment" {
  description = "Create the AKS subnet role assignment; disable only for emulators without Azure RBAC APIs"
  type        = bool
  default     = true
}
variable "kubernetes_version" {
  description = "Kubernetes version of the cluster; null takes the AKS default"
  type        = string
  default     = null
}
variable "node_count" {
  description = "Number of nodes of the default node pool"
  type        = number
  default     = 2
}
variable "vm_size" {
  description = "Azure VM size of the nodes of the default node pool"
  type        = string
  default     = "Standard_D2s_v5"
}
variable "service_cidr" {
  description = "IPv4 range of the Kubernetes services; must not overlap the VNet"
  type        = string
  default     = "172.20.0.0/16"
}
variable "dns_service_ip" {
  description = "Address of the cluster DNS service; must lie in `service_cidr`"
  type        = string
  default     = "172.20.0.10"
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDR blocks allowed to reach the Kubernetes API server. Required, so that an open API is a decision of the stack: the lab stacks set 0.0.0.0/0"
  type        = list(string)

  validation {
    condition     = length(var.api_server_authorized_ip_ranges) > 0 && alltrue([for c in var.api_server_authorized_ip_ranges : can(cidrhost(c, 0))])
    error_message = "api_server_authorized_ip_ranges must list at least one CIDR block, for example 203.0.113.0/24."
  }
}
