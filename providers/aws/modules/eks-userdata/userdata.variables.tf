variable "ami_type" {
  description = "EKS AMI type of the node group; selects the user-data format (AL2023 NodeConfig or Bottlerocket TOML). CUSTOM: own AL2023-based image"
  type        = string
  default     = "AL2023_x86_64_STANDARD"

  validation {
    condition     = contains(["AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64", "CUSTOM"], var.ami_type)
    error_message = "ami_type: AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64 or CUSTOM."
  }
}

variable "is_custom_ami" {
  description = "The launch template names the image: the user data then carries the cluster connection, which EKS does not add"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint of the cluster (only with `is_custom_ami = true`)"
  type        = string
  default     = null
}

variable "cluster_auth_base64" {
  description = "Certificate authority data of the cluster, base64 (only with `is_custom_ami = true`)"
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "Service CIDR of the cluster (`kubernetes_network_config.service_ipv4_cidr` of the cluster); required with `is_custom_ami = true`"
  type        = string
  default     = null
}

variable "max_pods" {
  description = "kubelet maxPods; null keeps the value of the image (the stack sets it per instance type)"
  type        = number
  default     = null
}

variable "kubelet_extra_config" {
  description = "KubeletConfiguration fields of the NodeConfig (reservations, eviction)"
  type        = any
  default     = {}
  nullable    = false
}

variable "kubelet_extra_args" {
  description = "Extra kubelet flags"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "bootstrap_labels" {
  description = "Node labels, Bottlerocket with `is_custom_ami = true` only (managed node groups set labels themselves)"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "bottlerocket_settings" {
  description = "Extra Bottlerocket TOML lines, for example settings.kernel.sysctl entries"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "pre_userdata" {
  description = "MIME parts placed before the CA and NodeConfig parts (AL2023)"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "post_userdata" {
  description = "MIME part placed after the NodeConfig part (AL2023)"
  type        = string
  default     = null
}

variable "ca_bundles" {
  description = "PEM bundles added to the trust store of the nodes (contents, not paths)"
  type        = list(string)
  default     = []
  nullable    = false
}
