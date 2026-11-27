output "oidc_provider_arn" {
  description = "ARN of the OIDC provider of the cluster"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "role_arns" {
  description = "Role ARNs by short name"
  value       = { for k, r in aws_iam_role.this : k => r.arn }
}
