variable "cloud" {
  description = "Cloud identifier, passed by Atmos from the stack context"
  type        = string
  default     = null
}

variable "tenant" {
  description = "Customer identifier, passed by Atmos from the stack context"
  type        = string
}

variable "stage" {
  description = "Stage name, passed by Atmos from the stack context"
  type        = string
}

variable "environment" {
  description = "Environment name; the names of the created resources start with it"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC of the Nexus VM"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet of the Nexus VM"
  type        = string
}

variable "ami_id" {
  description = "ID of the machine image of the Nexus VM"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type of the Nexus VM"
  type        = string
}

variable "nexus_version" {
  description = "Nexus Repository version installed on the VM"
  type        = string
}
variable "region" {
  description = "AWS region of the resources"
  type        = string
  default     = "us-east-1"
}

variable "local_endpoint" {
  description = "Floci endpoint of the local lab; null uses the real cloud APIs and the normal credential chain"
  type        = string
  default     = null
}

variable "nexus_wait_for_ready" {
  description = "Wait for Nexus readiness during OpenTofu apply"
  type        = bool
  default     = false
}

variable "nexus_readiness_url" {
  description = "Full Nexus writable-status endpoint URL"
  type        = string
  default     = null
}
