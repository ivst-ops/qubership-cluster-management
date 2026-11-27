# EKS managed add-ons (vpc-cni, kube-proxy, coredns, aws-ebs-csi-driver, ...), one for_each over typed inputs.
# Conflicts are overwritten on create: the add-on takes over the objects EKS installed itself.
resource "aws_eks_addon" "this" {
  for_each = var.addons

  cluster_name                = var.cluster_name
  addon_name                  = each.key
  addon_version               = each.value.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  service_account_role_arn    = each.value.service_account_role_arn
  preserve                    = each.value.preserve
  configuration_values        = length(each.value.configuration_values) > 0 ? jsonencode(each.value.configuration_values) : null

  tags = var.tags
}
