variable "cloud" {
  description = "Cloud identifier, passed by Atmos from the stack context"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name; the names of the created resources start with it"
  type        = string
}

variable "tenant" {
  description = "Customer identifier, passed by Atmos from the stack context"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "IPv4 address range for the VPC"
  type        = string
}

variable "stage" {
  description = "Stage name, passed by Atmos from the stack context"
  type        = string
}

variable "subnets" {
  description = "VPC subnets"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    public            = optional(bool, true)
  }))
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

variable "vpc_endpoints" {
  description = "VPC endpoints of the private-network profile by service key, for example `{ \"ecr.api\" = {}, s3 = { type = \"Gateway\" } }`; empty (default): none"
  type = map(object({
    type                = optional(string, "Interface")
    service_name        = optional(string)
    private_dns_enabled = optional(bool, true)
    policy              = optional(string)
  }))
  default = {}
}
