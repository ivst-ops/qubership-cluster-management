################################################################################
# Node Group
################################################################################
resource "aws_eks_node_group" "this" {
  cluster_name           = var.cluster_name
  node_group_name        = var.use_name_prefix ? null : var.node_group_name
  node_group_name_prefix = var.use_name_prefix ? format("%s-", var.node_group_name) : null

  dynamic "launch_template" {
    for_each = var.use_launch_template ? ["this"] : []
    content {
      id      = aws_launch_template.this[0].id
      version = coalesce(var.launch_template_version, aws_launch_template.this[0].latest_version)
    }
  }
  node_role_arn = var.iam_role_arn
  subnet_ids    = length(local.mng_allowed_az_for_subnet_filter) > 0 ? data.aws_subnets.this[0].ids : var.subnet_ids

  scaling_config {
    desired_size = var.mng_desired_size
    max_size     = var.mng_max_size
    min_size     = var.mng_min_size
  }

  capacity_type = var.capacity_type
  # With a launch template that names no image (use_custom_ami = false), EKS chooses the image by ami_type.
  ami_type             = local.eks_ami_type
  release_version      = var.use_launch_template && var.use_custom_ami ? null : var.ami_release_version
  disk_size            = var.use_launch_template ? null : var.root_volume_size
  instance_types       = var.use_launch_template ? null : var.override_instance_types
  force_update_version = var.force_update_version
  labels               = var.labels

  dynamic "update_config" {
    for_each = (var.update_config_max_unavailable_percentage == null && var.update_config_max_unavailable == null) ? [] : ["this"]
    content {
      max_unavailable            = var.update_config_max_unavailable_percentage == null ? var.update_config_max_unavailable : null
      max_unavailable_percentage = var.update_config_max_unavailable_percentage
    }
  }

  dynamic "remote_access" {
    for_each = (var.use_launch_template || var.ssh_key == null) ? [] : ["this"]
    content {
      ec2_ssh_key               = var.ssh_key
      source_security_group_ids = var.source_security_group_ids
    }
  }

  dynamic "node_repair_config" {
    for_each = var.node_repair_config != null ? [var.node_repair_config] : []

    content {
      enabled = node_repair_config.value.enabled
    }
  }

  dynamic "taint" {
    for_each = var.taint_install ? var.taints : []
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    var.mng_tags,
    {
      Name = var.node_group_name
    }
  )

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : ["this"]
    content {
      create = var.timeouts["create"]
      update = var.timeouts["update"]
      delete = var.timeouts["delete"]
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}


################################################################################
# Autoscaling Group Schedule
################################################################################
resource "aws_autoscaling_schedule" "this" {
  for_each = var.create_schedule ? var.schedules : {}

  scheduled_action_name  = each.key
  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name

  min_size         = try(each.value.min_size, null)
  max_size         = try(each.value.max_size, null)
  desired_capacity = try(each.value.desired_size, null)
  start_time       = try(each.value.start_time, null)
  end_time         = try(each.value.end_time, null)
  time_zone        = try(each.value.timezone, null)

  # [Minute] [Hour] [Day_of_Month] [Month_of_Year] [Day_of_Week]
  # Cron examples: https://crontab.guru/examples.html
  recurrence = try(each.value.recurrence, null)
}