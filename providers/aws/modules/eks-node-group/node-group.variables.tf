variable "ca_bundles" {
  description = "PEM bundles added to the trust store of the nodes (contents, not paths)"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region of the cluster; prefixes the availability-zone letters of `mng_allowed_az`"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC of the cluster"
  type        = string
}

variable "cluster_auth_b64" {
  description = "Certificate authority data of the cluster, base64 (only with `use_custom_ami = true`)"
  type        = string
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint of the cluster (only with `use_custom_ami = true`)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version of the cluster; selects the EKS image by name"
  type        = string
}

variable "tags" {
  description = "Tags of every resource of the node group; tags of the launch template override them for the Auto Scaling group"
  type        = map(string)
  default     = {}
}


################################################################################
# EKS Managed Node Group
################################################################################
variable "node_group_name" {
  description = "Name of the node group"
  type        = string
  nullable    = false
}

variable "use_name_prefix" {
  description = "Use `node_group_name` as a name prefix instead of the full name"
  type        = bool
  nullable    = false
  default     = false
}

variable "use_launch_template" {
  description = "Create a launch template for the node group"
  type        = bool
  nullable    = false
  default     = true
}

variable "launch_template_version" {
  description = "Version of the launch template; null takes the latest"
  type        = number
  nullable    = true
  default     = null
}

variable "use_custom_ami" {
  description = "The launch template names the image (the EKS image found by name, or `ami_id`); false lets EKS choose it by `ami_type`"
  type        = bool
  nullable    = false
  default     = true
}

variable "iam_role_arn" {
  description = "ARN of the IAM role of the nodes"
  type        = string
  nullable    = false
}

variable "mng_allowed_az" {
  description = "Availability-zone letters that narrow `subnet_ids` (for example `a`, `b`); `[\"*\"]` keeps every subnet"
  type        = list(string)
  nullable    = false
  default     = ["*"]
}

variable "subnet_ids" {
  description = "IDs of the subnets of the node group"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "mng_desired_size" {
  description = "Desired number of nodes"
  type        = number
  nullable    = false
  default     = 0
}

variable "mng_min_size" {
  description = "Minimum number of nodes"
  type        = number
  nullable    = false
  default     = 0
}

variable "mng_max_size" {
  description = "Maximum number of nodes"
  type        = number
  nullable    = false
  default     = 1
}

variable "capacity_type" {
  description = "Capacity type of the nodes: `ON_DEMAND` or `SPOT`"
  type        = string
  nullable    = false
  default     = "ON_DEMAND"
}

variable "ami_type" {
  description = "EKS AMI type: `AL2023_x86_64_STANDARD`, `AL2023_ARM_64_STANDARD`, `BOTTLEROCKET_x86_64` or `BOTTLEROCKET_ARM_64`; AL2023 by default"
  type        = string
  default     = "AL2023_x86_64_STANDARD"

  validation {
    condition     = contains(["AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64"], var.ami_type)
    error_message = "ami_type: AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD, BOTTLEROCKET_x86_64 or BOTTLEROCKET_ARM_64."
  }
}

variable "ami_id" {
  description = "ID of an own image; null searches the EKS image by name"
  type        = string
  nullable    = true
  default     = null
}

variable "ami_owner" {
  description = "Owner of the image named by `ami_id`"
  type        = string
  nullable    = true
  default     = "amazon"
}

variable "override_instance_types" {
  description = "Instance types of the node group without a launch template"
  type        = list(string)
  nullable    = false
  default     = ["t3.medium"]
}

variable "force_update_version" {
  description = "Update the nodes even when a pod disruption budget blocks their drain"
  type        = bool
  nullable    = false
  default     = false
}

variable "labels" {
  description = "Kubernetes labels of the nodes, managed through the EKS API"
  type        = map(string)
  nullable    = true
  default     = null
}

variable "update_config_max_unavailable" {
  description = "Maximum number of nodes unavailable during an update"
  type        = number
  nullable    = true
  default     = 1 # nodes are updated one at a time by default
}

variable "update_config_max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during an update; replaces `update_config_max_unavailable` when set"
  type        = number
  nullable    = true
  default     = null
}

variable "ssh_key" {
  description = "Name of the EC2 key pair of the nodes; without a launch template also set `source_security_group_ids`"
  type        = string
  nullable    = true
  default     = null
}

variable "source_security_group_ids" {
  description = "Security groups allowed to reach the nodes over SSH (port 22), without a launch template only"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "taint_install" {
  description = "Apply `taints` to the nodes"
  type        = bool
  nullable    = false
  default     = false
}

variable "taints" {
  description = "Kubernetes taints of the nodes (at most 50)"
  type = list(object({
    key    = string
    value  = optional(string, null)
    effect = string
  }))
  nullable = false
  default  = []
}

variable "mng_tags" {
  description = "Tags of the node group in addition to `tags`"
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "timeouts" {
  description = "Create, update and delete timeouts of the node group"
  type = object({
    create = optional(string, "20m")
    update = optional(string, "30m")
    delete = optional(string, "20m")
  })
  nullable = false
  default = {
    create = "20m"
    update = "30m"
    delete = "20m"
  }
}

variable "node_repair_config" {
  description = "Automatic node repair of EKS; null leaves it off"
  type = object({
    enabled = optional(bool, true)
  })
  default = null
}


################################################################################
# EKS Managed Node Group - launch template specific variables
################################################################################
variable "launch_template_name" {
  description = "Name of the launch template; null makes OpenTofu generate a unique name"
  type        = string
  nullable    = true
  default     = null
}

variable "ami_release_version" {
  description = "Release filter of the image search (wildcards allowed, the latest match wins), or the EKS release version without a launch-template image"
  type        = string
  nullable    = true
  default     = null
}

variable "instance_type" {
  description = "Instance type of the launch template; without a launch template use `override_instance_types`"
  type        = string
  nullable    = false
  default     = "t3.medium"
}

variable "public_ip" {
  description = "Associate a public IP address with the network interface of the nodes"
  type        = bool
  nullable    = false
  default     = false
}

variable "eni_delete" {
  description = "Delete the network interface when the instance terminates"
  type        = bool
  nullable    = false
  default     = true
}

variable "worker_security_group_id" {
  description = "Security group of every node"
  type        = string
}

variable "additional_security_group_ids" {
  description = "Security groups of the nodes in addition to `worker_security_group_id`"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "enclave_support" {
  description = "Enable Nitro Enclaves on the nodes"
  type        = bool
  nullable    = false
  default     = false
}

variable "metadata_http_endpoint" {
  description = "Instance metadata service: `enabled` or `disabled`"
  type        = string
  nullable    = false
  default     = "enabled"
}

variable "metadata_http_tokens" {
  description = "Session tokens of the instance metadata service (IMDSv2): `optional` or `required`"
  type        = string
  nullable    = false
  default     = "required"
}

variable "metadata_http_put_response_hop_limit" {
  description = "HTTP PUT response hop limit of instance metadata requests"
  type        = number
  nullable    = false
  default     = 2
}

variable "cpu_credits" {
  description = "CPU credit option of burstable instances: `standard` or `unlimited`"
  type        = string
  nullable    = false
  default     = "standard"
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring of the nodes"
  type        = bool
  nullable    = false
  default     = false
}


variable "launch_template_placement_group" {
  description = "Placement group of the nodes"
  type        = string
  nullable    = true
  default     = null
}

variable "launch_template_placement_tenancy" {
  description = "Tenancy of the nodes: `default`, `dedicated` or `host`; only with `launch_template_placement_group`"
  type        = string
  nullable    = false
  default     = "default"
}

variable "encrypted" {
  description = "Encrypt every volume of the nodes"
  type        = bool
  nullable    = false
  default     = true # quality gate of the prototype: encrypted volumes
}

variable "kms_key_id" {
  description = "KMS key of the encrypted volumes; requires `encrypted = true`"
  type        = string
  nullable    = false
  default     = "alias/aws/ebs"
}
variable "ebs_optimized" {
  description = "Make the nodes EBS-optimized; null decides by instance type"
  type        = bool
  nullable    = true
  default     = null
}

variable "root_block_device_name" {
  description = "Device name of the root volume; null takes the one of the image"
  type        = string
  nullable    = true
  default     = null
}

variable "root_volume_size" {
  description = "Size of the root volume, GiB"
  type        = number
  nullable    = false
  default     = 50
}

variable "root_volume_type" {
  description = "Type of the root volume: `standard`, `gp2`, `gp3`, `io1`, `io2`, `sc1` or `st1`"
  type        = string
  nullable    = false
  default     = "gp3"
}

variable "root_iops" {
  description = "Provisioned IOPS of the root volume, for `io1`, `io2` or `gp3`"
  type        = number
  nullable    = true
  default     = null
}

variable "root_throughput" {
  description = "Throughput of a `gp3` root volume, MiB/s (at most 1000)"
  type        = number
  nullable    = true
  default     = null
}

variable "additional_ebs_volumes" {
  description = "Additional EBS volumes of every node"
  type = list(object({
    block_device_name     = string
    volume_size           = number
    volume_type           = optional(string, "gp3")
    iops                  = optional(number, null)
    throughput            = optional(number, null)
    delete_on_termination = optional(bool, true)
  }))
  nullable = false
  default  = []
}

variable "pre_userdata" {
  description = "MIME parts placed before the node bootstrap (AL2023 only)"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "additional_userdata" {
  description = "MIME part placed after the node bootstrap (AL2023 only)"
  type        = string
  nullable    = true
  default     = null
}

variable "bottlerocket_settings" {
  description = "Extra Bottlerocket TOML lines"
  type        = list(string)
  nullable    = false
  default = [
    "settings.host-containers.control.enabled = false",
    "settings.host-containers.admin.enabled = false"
  ]
}

variable "kubelet_extra_args" {
  description = "Extra kubelet flags; prefer `kubelet_extra_config`"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "kubelet_extra_config" {
  description = "KubeletConfiguration fields of the NodeConfig (reservations, eviction)"
  type        = any
  nullable    = true
  default     = null
}

variable "max_pods" {
  description = "kubelet maxPods; null keeps the value of the image (the stack sets it per instance type)"
  type        = number
  default     = null # null keeps the maxPods of the image; the stack sets it per instance type
}

variable "enable_tag_specifications" {
  description = "Tag the instances, volumes and network interfaces through the launch template"
  type        = bool
  nullable    = false
  default     = true
}


################################################################################
# Autoscaling Group Schedule
################################################################################
variable "create_schedule" {
  description = "Create the scaling schedules of `schedules`"
  type        = bool
  nullable    = false
  default     = false
}
variable "schedules" {
  description = "Scaling schedules of the Auto Scaling group by name; only with `create_schedule = true`"
  type        = map(any)
  nullable    = false
  default     = {}
}
variable "service_cidr" {
  description = "Service CIDR of the cluster (`kubernetes_network_config.service_ipv4_cidr` of the cluster)"
  type        = string
}
