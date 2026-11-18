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
