variable "cluster_name" {
  description = "EKS cluster of the add-ons"
  type        = string
}

variable "addons" {
  description = "Add-ons by EKS add-on name (vpc-cni, kube-proxy, coredns, aws-ebs-csi-driver, ...); version null takes the default of the cluster version"
  type = map(object({
    version                     = optional(string)
    configuration_values        = optional(any, {})
    service_account_role_arn    = optional(string)
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    preserve                    = optional(bool, true)
  }))
  default = {}

  validation {
    condition     = alltrue([for a in values(var.addons) : contains(["OVERWRITE", "PRESERVE", "NONE"], a.resolve_conflicts_on_update)])
    error_message = "resolve_conflicts_on_update must be OVERWRITE, PRESERVE or NONE."
  }
}

variable "tags" {
  description = "Tags of the add-ons (the provider adds the cost tags)"
  type        = map(string)
  default     = {}
}
