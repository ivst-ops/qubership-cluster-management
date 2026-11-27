variable "cloud" {
  description = "Cloud identifier, passed by Atmos from the stack context"
  type        = string
  default     = null
}

variable "stage" {
  description = "Stage name, passed by Atmos from the stack context"
  type        = string
}

variable "environment" {
  description = "Environment name; the names of the created resources start with it"
  type        = string
}

variable "kubeconfig_path" {
  description = "Kubeconfig for this deployment; null preserves the environment-based path"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC of the load balancer and its target groups"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets, by subnet key"
  type        = map(string)
}

variable "tenant" {
  description = "Customer identifier, passed by Atmos from the stack context"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the HTTPS listener. Set: HTTPS on port 443 (TLS 1.3/1.2 policy) and HTTP redirects to it. Null: plain HTTP only"
  type        = string
  default     = null

  validation {
    condition     = var.certificate_arn == null || can(regex("^arn:[a-z-]+:acm:", var.certificate_arn))
    error_message = "certificate_arn must be an ACM certificate ARN (arn:aws:acm:...)."
  }
}

variable "headlamp_node_port" {
  description = "Node port of the Headlamp service on the cluster nodes"
  type        = number
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
