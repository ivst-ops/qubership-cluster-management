variable "ca_bundles" {
  description = "PEM bundles added to the trust store of the nodes (contents, not paths)"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "cluster_auth_b64" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
  default     = {}
}


################################################################################
# EKS Managed Node Group
################################################################################
variable "node_group_name" {
  description = "name of the node gorup"
  type        = string
  nullable    = false
}

variable "use_name_prefix" {
  description = "Whether to use node_group_name value as name prefix"
  type        = bool
  nullable    = false
  default     = false
}

variable "use_launch_template" {
  description = "Whether to use launch template"
  type        = bool
  nullable    = false
  default     = true
}

variable "launch_template_version" {
  description = "version of the launch template"
  type        = number
  nullable    = true
  default     = null
}

variable "use_custom_ami" {
  description = "Whether to use custom AMI (If AMI is specified in launch template, then it's called custom AMI)"
  type        = bool
  nullable    = false
  default     = true
}

variable "iam_role_arn" {
  description = "IAM role ARN for node"
  type        = string
  nullable    = false
}

variable "mng_allowed_az" {
  description = "Per-AZ suffix letters for subnet discovery (e.g. \"a\", \"b\" -> us-east-1a). Default [\"*\"] skips the availability-zone filter (all AZs allowed among candidate subnets). With explicit subnet_ids, this still narrows the list to subnets in these AZs."
  type        = list(string)
  nullable    = false
  default     = ["*"]
}

variable "subnet_ids" {
  description = "Identifiers of EC2 Subnets to associate with the EKS Node Group. These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME`"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "mng_desired_size" {
  description = "desired size of node group"
  type        = number
  nullable    = false
  default     = 0
}

variable "mng_min_size" {
  description = "min size of node group"
  type        = number
  nullable    = false
  default     = 0
}

variable "mng_max_size" {
  description = "max size of node group"
  type        = number
  nullable    = false
  default     = 1
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  nullable    = false
  default     = "ON_DEMAND"
}

variable "ami_type" {
  description = "EKS AMI type: AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD, BOTTLEROCKET_x86_64 or BOTTLEROCKET_ARM_64; AL2023 by default"
  type        = string
  default     = "AL2023_x86_64_STANDARD"

  validation {
    condition     = contains(["AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64"], var.ami_type)
    error_message = "ami_type: AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD, BOTTLEROCKET_x86_64 or BOTTLEROCKET_ARM_64."
  }
}

variable "ami_id" {
  description = "AMI ID, required if AMI type is custom linux"
  type        = string
  nullable    = true
  default     = null
}

variable "ami_owner" {
  description = "AMI owner, valid only if AMI type is cutsom linux. Default: 'amazon'"
  type        = string
  nullable    = true
  default     = "amazon"
}

variable "override_instance_types" {
  description = "List of instance types associated with the EKS Node Group. Applicable when launch template is not used"
  type        = list(string)
  nullable    = false
  default     = ["t3.medium"]
}

variable "force_update_version" {
  description = "Force version update if existing pods are unable to be drained due to a pod disruption budget issue"
  type        = bool
  nullable    = false
  default     = false
}

variable "labels" {
  description = "Key-value map of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed."
  type        = map(string)
  nullable    = true
  default     = null
}

variable "update_config_max_unavailable" {
  description = "Desired max number of unavailable worker nodes during node group update."
  type        = number
  nullable    = true
  default     = 1 # nodes are updated one at a time by default
}

variable "update_config_max_unavailable_percentage" {
  description = "Desired max percentage of unavailable worker nodes during node group update. This is ignored if `update_config_max_unavailable is set`"
  type        = number
  nullable    = true
  default     = null
}

variable "ssh_key" {
  description = "The SSH key name to use for the instance. If launch template is not used, set source_security_group_ids too to restrict SSH access to specific subnet/ips"
  type        = string
  nullable    = true
  default     = null
}

variable "source_security_group_ids" {
  description = "Set of EC2 Security Group IDs to allow SSH access (port 22) from on the worker nodes. Applicable only when launch template is not used."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "taint_install" {
  description = "Whether to add taints to node group"
  type        = bool
  nullable    = false
  default     = false
}

variable "taints" {
  description = "The Kubernetes taints to be applied to the nodes in the node group. Maximum of 50 taints per node group."
  type = list(object({
    key    = string
    value  = optional(string, null)
    effect = string
  }))
  nullable = false
  default  = []
}

variable "mng_tags" {
  description = "Tags as key-value pairs for node group"
  type        = map(any)
  nullable    = false
  default     = {}
}

variable "timeouts" {
  description = "Timeouts for node group changes."
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
  description = "The node auto repair configuration for the node group"
  type = object({
    enabled = optional(bool, true)
  })
  default = null
}


################################################################################
# EKS Managed Node Group - launch template specific variables
################################################################################
variable "launch_template_name" {
  description = "The name of the launch template. If you leave this blank, Terraform will auto-generate a unique name"
  type        = string
  nullable    = true
  default     = null
}

variable "ami_release_version" {
  description = "release name filter for ami search. If multiple results, latest will be used. Wild cards are accepted. (the AMI search of a custom AMI, or the EKS release version without one)"
  type        = string
  nullable    = true
  default     = null
}

variable "instance_type" {
  description = "instance type to be specified in launch template. If no launch template is used, then set override_instance_types instead"
  type        = string
  nullable    = false
  default     = "t3.medium"
}

variable "public_ip" {
  description = "Whether to associate a public ip address with the network interface."
  type        = bool
  nullable    = false
  default     = false
}

variable "eni_delete" {
  description = "Whether the network interface should be destroyed on instance termination."
  type        = bool
  nullable    = false
  default     = true
}

variable "worker_security_group_id" {
  description = "Common Security Group for all Worker nodes"
  type        = string
}

variable "additional_security_group_ids" {
  description = "A list of additional security group ids if any along with worker security group ids"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "enclave_support" {
  description = "Whether Nitro Enclaves will be enabled on the instance."
  type        = bool
  nullable    = false
  default     = false
}

variable "metadata_http_endpoint" {
  description = "Whether the metadata service is available. Can be `enabled` or `disabled`"
  type        = string
  nullable    = false
  default     = "enabled"
}

variable "metadata_http_tokens" {
  description = "Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2 (IMDSv2). Can be `optional` or `required`"
  type        = string
  nullable    = false
  default     = "required"
}

variable "metadata_http_put_response_hop_limit" {
  description = "The desired HTTP PUT response hop limit for instance metadata requests"
  type        = number
  nullable    = false
  default     = 2
}

variable "cpu_credits" {
  description = "The credit option for CPU usage. Can be standard or unlimited"
  type        = string
  nullable    = false
  default     = "standard"
}

variable "enable_monitoring" {
  description = "Whether or not the monitoring option for the instance is enabled."
  type        = bool
  nullable    = false
  default     = false
}


variable "launch_template_placement_group" {
  description = "The name of the placement group for the instance."
  type        = string
  nullable    = true
  default     = null
}

variable "launch_template_placement_tenancy" {
  description = "The tenancy of the instance (if the instance is running in a VPC). Can be default, dedicated, or host. Applicable only when `launch_template_placement_group` is set"
  type        = string
  nullable    = false
  default     = "default"
}

variable "encrypted" {
  description = "Default encryption option for all volumes."
  type        = bool
  nullable    = false
  default     = true # quality gate of the prototype: encrypted volumes
}

variable "kms_key_id" {
  description = "The ARN of the AWS Key Management Service (AWS KMS) customer master key (CMK) to use when creating the encrypted volume. encrypted must be set to true when this is set"
  type        = string
  nullable    = false
  default     = "alias/aws/ebs"
}
variable "ebs_optimized" {
  description = " If true, the launched EC2 instance will be EBS-optimized."
  type        = bool
  nullable    = true
  default     = null
}

variable "root_block_device_name" {
  description = "The name of the root device"
  type        = string
  nullable    = true
  default     = null
}

variable "root_volume_size" {
  description = "The size of the volume in gigabytes"
  type        = number
  nullable    = false
  default     = 50
}

variable "root_volume_type" {
  description = "The volume type. Can be one of standard, gp2, gp3, io1, io2, sc1 or st1"
  type        = string
  nullable    = false
  default     = "gp3"
}

variable "root_iops" {
  description = "The amount of provisioned IOPS. This must be set with a volume_type of `io1/io2/gp3`"
  type        = number
  nullable    = true
  default     = null
}

variable "root_throughput" {
  description = "The throughput to provision for a gp3 volume in MiB/s (specified as an integer, e.g., 500), with a maximum of 1,000 MiB/s."
  type        = number
  nullable    = true
  default     = null
}

variable "additional_ebs_volumes" {
  description = "A list of additional volumes to be attached to the instances on this Auto Scaling group."
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
  description = "pre-kubelet bootstrap userdata, applicable only for non-bottlerocket linux instances"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "additional_userdata" {
  description = "post-kubelet bootstrap userdata, applicable only for non-bottlerocket linux instances"
  type        = string
  nullable    = true
  default     = null
}

variable "bottlerocket_settings" {
  description = "list of bottlerocket settings"
  type        = list(string)
  nullable    = false
  default = [
    "settings.host-containers.control.enabled = false",
    "settings.host-containers.admin.enabled = false"
  ]
}

variable "kubelet_extra_args" {
  description = "list of kubelet extra args. (Deprecated) - Use kubelet_extra_config instead for override kublet config"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "kubelet_extra_config" {
  description = "list of kubelet override config"
  type        = any
  nullable    = true
  default     = null
}

variable "max_pods" {
  description = "max pods"
  type        = number
  default     = null # null keeps the maxPods of the image; the stack sets it per instance type
}

variable "enable_tag_specifications" {
  description = "Whether or not the tag specifications option for the launch template is enabled."
  type        = bool
  nullable    = false
  default     = true
}


################################################################################
# Autoscaling Group Schedule
################################################################################
variable "create_schedule" {
  description = "create ASG schedule. Applicable only when launch template is not used"
  type        = bool
  nullable    = false
  default     = false
}
variable "schedules" {
  description = "Key-Value pair of schedule map. Applicable only when create_schedule is set to `true`"
  type        = map(any)
  nullable    = false
  default     = {}
}
variable "service_cidr" {
  description = "Service CIDR of the cluster (aws_eks_cluster kubernetes_network_config.service_ipv4_cidr)"
  type        = string
}
