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
  description = "Environment name; names the Kubemarine cluster (`<environment>.local`) and its working directory"
  type        = string
}

variable "nodes" {
  description = "Cluster VMs as output by any `<cloud>/vms` component; roles are Kubemarine roles"
  type = list(object({
    name             = string
    roles            = list(string)
    address          = string
    internal_address = string
  }))
}

variable "jump_host" {
  description = "Jump host VM (any `<cloud>/vms` output entry); Kubemarine reaches the nodes through it"
  type = object({
    address = string
  })
}

variable "nexus_address" {
  description = "Private address of the Nexus VM loaded by `bundle/load.sh`"
  type        = string
}

variable "mirrored_registries" {
  description = "Registries of application images; containerd pulls `<registry>/<path>` from Nexus (`bundle/manifest.yaml` `app_images`)"
  type        = list(string)
}

variable "ssh_user" {
  description = "User that Kubemarine connects as over SSH, on the nodes and the jump host"
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key" {
  description = "Key for the jump host and the nodes (TF_VAR_ssh_private_key from sops exec-env)"
  type        = string
  sensitive   = true
}

variable "kubemarine" {
  description = "Extra `cluster.yaml` fields (for example `services`, `plugins`); the generated `nodes`, `gateway_nodes`, `registry`, package repositories and containerd mirrors are applied on top, so of the generated fields only `cluster_name` can be overridden"
  type        = any
  default     = {}
}
