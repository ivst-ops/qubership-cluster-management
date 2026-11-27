output "userdata" {
  description = "User data of the launch template, base64"
  value       = base64encode(local.userdata)

  precondition {
    condition     = !var.is_custom_ami || (var.service_cidr != null && var.cluster_endpoint != null && var.cluster_auth_base64 != null)
    error_message = "A custom AMI needs service_cidr, cluster_endpoint and cluster_auth_base64 (EKS adds no cluster connection)."
  }
}

output "userdata_decoded" {
  description = "User data of the launch template, plain text"
  value       = local.userdata
}

output "nodeconfig" {
  description = "NodeConfig written into the AL2023 user data, null when there is none (for tests and reviews)"
  value       = local.family == "al2023" ? local.nodeconfig : null
}
