variable "cloud" {
  description = "Cloud identifier supplied by Atmos as deployment context"
  type        = string
  default     = null
}

variable "stage" {
  type = string
}

variable "environment" {
  type = string
}

variable "kubeconfig_path" {
  description = "Kubeconfig for this deployment; null preserves the environment-based path"
  type        = string
  default     = null
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = map(string)
}

variable "tenant" {
  type    = string
  default = null
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
  type = number
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
