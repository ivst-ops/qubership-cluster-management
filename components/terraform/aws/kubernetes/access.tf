# EKS access entries: who may use the Kubernetes API, with an EKS access policy for the whole cluster. The lab entry
# spells out policy_arn: merge() does not apply the optional() defaults of access_entries to it.
locals {
  access_entries = merge(
    var.access_entries,
    var.local_endpoint != null ? {
      lab = { principal_arn = aws_iam_user.kubectl.arn, policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" }
    } : {}
  )
}

resource "aws_eks_access_entry" "this" {
  for_each = local.access_entries

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value.principal_arn
}

resource "aws_eks_access_policy_association" "this" {
  for_each = local.access_entries

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.this[each.key].principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type = "cluster"
  }
}
