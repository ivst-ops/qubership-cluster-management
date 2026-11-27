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
  description = "Google Cloud project of the VMs"
  type        = string
}
variable "name" {
  description = "Group name: resource name prefix and network tag"
  type        = string
}

variable "location" {
  description = "Zone for the VMs"
  type        = string
}
variable "vpc_id" {
  description = "ID of the VPC network of the VMs"
  type        = string
}
variable "subnet_ids" {
  description = "IDs of the subnets, by subnet key"
  type        = map(string)
}
variable "image" {
  description = "Boot image of the VMs, as project/image or project/family"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}
variable "ssh_public_key" {
  description = "Public half of the SOPS-stored key (TF_VAR_ssh_public_key from sops exec-env)"
  type        = string
}
variable "vms" {
  description = "VMs by name; roles are Kubemarine roles or empty; `instance_type` is the machine type"
  type = map(object({
    roles         = optional(list(string), [])
    instance_type = string
    subnet        = string
    volume_size   = optional(number, 50)
  }))
}
variable "public" {
  description = "Give the VMs external IPs"
  type        = bool
  default     = false
}
variable "ports" {
  description = "TCP ports open to `allowed_cidrs`"
  type        = list(number)
  default     = [22]
}
variable "allowed_cidrs" {
  description = "Sources for ports: the subnet CIDR for private groups, operator CIDRs for the jump host"
  type        = list(string)
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
