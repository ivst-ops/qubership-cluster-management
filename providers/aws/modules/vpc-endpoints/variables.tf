variable "name" {
  description = "Prefix of the resource names, usually the environment"
  type        = string
}

variable "region" {
  description = "AWS region; service names default to com.amazonaws.<region>.<key>"
  type        = string
}

variable "vpc_id" {
  description = "VPC of the endpoints"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 range allowed to reach the interface endpoints over HTTPS"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets of the interface endpoints (one per availability zone)"
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "Route tables that get the routes of the gateway endpoints"
  type        = list(string)
  default     = []
}

variable "endpoints" {
  description = "Endpoints by service key (ecr.api, ecr.dkr, s3, sts, ec2, ...). service_name overrides com.amazonaws.<region>.<key>"
  type = map(object({
    type                = optional(string, "Interface")
    service_name        = optional(string)
    private_dns_enabled = optional(bool, true)
    policy              = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for e in values(var.endpoints) : contains(["Interface", "Gateway"], e.type)])
    error_message = "endpoints[*].type must be Interface or Gateway."
  }
}

variable "tags" {
  description = "Tags of the endpoints and the security group (the provider adds the cost tags)"
  type        = map(string)
  default     = {}
}
