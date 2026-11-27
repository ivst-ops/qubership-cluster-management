#################################################
# Subnets 
# only when narrowing var.subnet_ids by mng_allowed_az (intersect subnet IDs with AZs).
# If mng_allowed_az is default ["*"], unused; aws_eks_node_group uses var.subnet_ids directly.
#################################################
data "aws_subnets" "this" {
  count = length(local.mng_allowed_az_for_subnet_filter) > 0 ? 1 : 0

  filter {
    name   = "subnet-id"
    values = var.subnet_ids
  }
  filter {
    name   = "availability-zone"
    values = local.mng_allowed_az_for_subnet_filter
  }
}


#################################################
# AMI
#################################################
data "aws_ami" "eks_worker" {
  count = var.use_launch_template ? 1 : 0

  dynamic "filter" {
    for_each = var.ami_id == null ? { "ami_type" : var.ami_type } : {}
    content {
      name   = "name"
      values = [try(local.ami_format_map[var.ami_type], null)]
    }
  }
  dynamic "filter" {
    for_each = var.ami_id != null ? { "ami_type" : var.ami_type } : {}
    content {
      name   = "image-id"
      values = [var.ami_id]
    }
  }

  most_recent = true
  owners = [
    var.ami_id == null ? "amazon" : var.ami_owner
  ]
}


#################################################
# KMS Key Alias
#################################################
data "aws_kms_key" "ebs" {
  count  = var.encrypted ? 1 : 0
  key_id = var.kms_key_id
}

#################################################
# The default tags
#################################################
data "aws_default_tags" "this" {}