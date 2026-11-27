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
variable "name" {
  description = "Group name: resource name prefix and the first Role tag"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group of the VMs"
  type        = string
}
variable "subnet_ids" {
  description = "IDs of the subnets, by subnet key"
  type        = map(string)
}
variable "image" {
  description = "Marketplace image of the VMs: publisher, offer, SKU and version"
  type        = object({ publisher = string, offer = string, sku = string, version = string })
  default = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
variable "ssh_public_key" {
  description = "Public half of the SOPS-stored key (TF_VAR_ssh_public_key from sops exec-env)"
  type        = string
}
variable "vms" {
  description = "VMs by name; roles are Kubemarine roles or empty; `instance_type` is the VM size"
  type = map(object({
    roles         = optional(list(string), [])
    instance_type = string
    subnet        = string
    volume_size   = optional(number, 50)
  }))
}
variable "public" {
  description = "Give the VMs public IPs"
  type        = bool
  default     = false
}
variable "ports" {
  description = "TCP ports open to `allowed_cidrs`"
  type        = list(number)
  default     = [22]
}
variable "allowed_cidrs" {
  description = "Sources for ports: the VNet CIDR for private groups, operator CIDRs for the jump host"
  type        = list(string)
}
