variable "cloud" {
  description = "Cloud identifier supplied by Atmos as deployment context"
  type        = string
  default     = null
}

variable "stage" {
  description = "Name of the stage from Atmos"
  type        = string
}

variable "tenant" {
  description = "Customer identifier supplied by Atmos"
  type        = string
  default     = null
}

variable "environment" {
  description = "Name of the environment"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets for the cluster"
  type        = map(string)
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "local_endpoint" {
  description = "Floci endpoint; null uses the real AWS APIs and normal credential chain"
  type        = string
  default     = null
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public Kubernetes API endpoint. Empty (default): no public endpoint, the API is reachable from inside the VPC only. The lab stacks set 0.0.0.0/0"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.public_access_cidrs : can(cidrhost(c, 0))])
    error_message = "public_access_cidrs must be CIDR blocks, for example 203.0.113.0/24."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes minor version of the cluster, e.g. \"1.34\"; null takes the EKS default"
  type        = string
  default     = null
}

variable "authentication_mode" {
  description = "EKS authentication mode: API (access entries only, the default) or API_AND_CONFIG_MAP while moving an older cluster"
  type        = string
  default     = "API"

  validation {
    condition     = contains(["API", "API_AND_CONFIG_MAP"], var.authentication_mode)
    error_message = "authentication_mode must be API or API_AND_CONFIG_MAP."
  }
}

variable "access_entries" {
  description = "IAM principals allowed to use the Kubernetes API (operators, runners), with an EKS access policy for the whole cluster"
  type = map(object({
    principal_arn = string
    policy_arn    = optional(string, "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy")
  }))
  default = {}
}

variable "addons" {
  description = "EKS managed add-ons by name. before_nodes: installed with the cluster (CNI, kube-proxy), otherwise after the node groups. irsa_role: a key of irsa_roles"
  type = map(object({
    version                     = optional(string)
    configuration_values        = optional(any, {})
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    preserve                    = optional(bool, true)
    before_nodes                = optional(bool, false)
    irsa_role                   = optional(string)
  }))
  default = {}
}

variable "irsa_enabled" {
  description = "Create the OIDC provider of the cluster and the roles of irsa_roles"
  type        = bool
  default     = false
}

variable "irsa_roles" {
  description = "IAM roles for service accounts by short name: namespace, service account and AWS managed policies"
  type = map(object({
    namespace       = string
    service_account = string
    policy_arns     = list(string)
  }))
  default = {}
}
