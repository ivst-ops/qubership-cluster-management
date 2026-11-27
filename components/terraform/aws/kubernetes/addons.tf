# Managed add-ons, OIDC provider and IAM roles for service accounts. Add-ons marked before_nodes (the CNI, kube-proxy)
# are installed with the cluster; the others (coredns, the CSI driver) wait for the node groups, because they stay
# degraded without nodes.
module "irsa" {
  count  = var.irsa_enabled ? 1 : 0
  source = "../../../../providers/aws/modules/eks-irsa"

  cluster_name    = aws_eks_cluster.main.name
  oidc_issuer_url = aws_eks_cluster.main.identity[0].oidc[0].issuer
  roles           = var.irsa_roles
}

locals {
  # An add-on names its role by the short name of irsa_roles.
  addons = {
    for k, a in var.addons : k => {
      before_nodes = a.before_nodes
      addon = {
        version                     = a.version
        configuration_values        = a.configuration_values
        resolve_conflicts_on_update = a.resolve_conflicts_on_update
        preserve                    = a.preserve
        service_account_role_arn    = a.irsa_role == null ? null : module.irsa[0].role_arns[a.irsa_role]
      }
    }
  }
}

module "addons_before_nodes" {
  source = "../../../../providers/aws/modules/eks-addons"

  cluster_name = aws_eks_cluster.main.name
  addons       = { for k, a in local.addons : k => a.addon if a.before_nodes }
}

module "addons" {
  source = "../../../../providers/aws/modules/eks-addons"

  cluster_name = aws_eks_cluster.main.name
  addons       = { for k, a in local.addons : k => a.addon if !a.before_nodes }

  depends_on = [module.node_groups]
}
