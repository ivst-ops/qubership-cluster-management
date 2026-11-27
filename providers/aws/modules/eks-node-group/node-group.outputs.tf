output "ami_info" {
  value = data.aws_ami.eks_worker
}

output "autoscaling_group_name" {
  value = try(aws_eks_node_group.this.resources[0].autoscaling_groups[0].name, null)
}
output "eks_ami_type" {
  description = "AMI type given to EKS; null when the launch template names a custom image"
  value       = local.eks_ami_type
}
