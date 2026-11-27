# IAM roles for service accounts: the OIDC provider of the cluster and one role per service account with AWS managed
# policies (for example AmazonEBSCSIDriverPolicy). No thumbprint: IAM does not need one for EKS issuers.
locals {
  issuer = replace(var.oidc_issuer_url, "https://", "")
}

resource "aws_iam_openid_connect_provider" "this" {
  url            = var.oidc_issuer_url
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

resource "aws_iam_role" "this" {
  for_each = var.roles

  name = "${var.cluster_name}-${each.key}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.this.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.issuer}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
          "${local.issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for p in flatten([for k, r in var.roles : [for a in r.policy_arns : { key = "${k}/${a}", role = k, arn = a }]]) : p.key => p }

  role       = aws_iam_role.this[each.value.role].name
  policy_arn = each.value.arn
}
