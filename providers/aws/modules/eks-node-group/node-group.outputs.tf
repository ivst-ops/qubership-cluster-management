output "ami_info" {
  description = "The machine image found for the launch template (empty without a launch template)"
  value       = data.aws_ami.eks_worker
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling group behind the node group; null before EKS reports it"
  value       = try(aws_eks_node_group.this.resources[0].autoscaling_groups[0].name, null)
}
output "eks_ami_type" {
  description = "AMI type given to EKS; null when `use_custom_ami = true` and the launch template names the image"
  value       = local.eks_ami_type
}

output "update_settings" {
  description = "Update and repair settings sent to EKS (for tests and reviews)"
  value = {
    max_unavailable            = var.update_config_max_unavailable_percentage == null ? var.update_config_max_unavailable : null
    max_unavailable_percentage = var.update_config_max_unavailable_percentage
    force_update_version       = var.force_update_version
    auto_repair                = try(var.node_repair_config.enabled, false)
  }
}
