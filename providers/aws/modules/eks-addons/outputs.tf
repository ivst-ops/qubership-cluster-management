output "versions" {
  description = "Installed version of each add-on"
  value       = { for k, a in aws_eks_addon.this : k => a.addon_version }
}
