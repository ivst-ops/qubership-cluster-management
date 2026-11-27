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

variable "vpc_cidr" {
  description = "IPv4 address range of the VNet"
  type        = string
}
variable "subnets" {
  description = "VNet subnets by key; `public = false` turns off default outbound Internet access for VMs without a public IP"
  type = map(object({
    cidr_block = string
    public     = optional(bool, true)
  }))
}
