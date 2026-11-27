variable "cluster_name" {
  description = "EKS cluster; prefix of the role names"
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer of the cluster (`aws_eks_cluster.identity`[0].oidc[0].issuer)"
  type        = string
}

variable "roles" {
  description = "Roles by short name: the service account that may assume it and the managed policies it gets"
  type = map(object({
    namespace       = string
    service_account = string
    policy_arns     = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags of the provider and the roles (the provider adds the cost tags)"
  type        = map(string)
  default     = {}
}
