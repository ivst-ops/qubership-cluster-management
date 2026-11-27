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
  description = "Google Cloud project of the network"
  type        = string
}

variable "subnet_cidr" {
  description = "Primary IPv4 range of the subnet"
  type        = string
}
variable "pod_cidr" {
  description = "Secondary IPv4 range of the subnet for the pods"
  type        = string
  default     = "10.100.0.0/16"
}
variable "service_cidr" {
  description = "Secondary IPv4 range of the subnet for the Kubernetes services"
  type        = string
  default     = "10.110.0.0/20"
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
