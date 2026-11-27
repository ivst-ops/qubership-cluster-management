mock_provider "aws" {
  mock_resource "aws_iam_openid_connect_provider" {
    defaults = { arn = "arn:aws:iam::000000000000:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLE" }
  }
}

variables {
  cluster_name    = "t-s-eks"
  oidc_issuer_url = "https://oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLE"
  roles = {
    ebs-csi = {
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
      policy_arns     = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
    }
  }
}

run "role_trusts_only_its_service_account" {
  command = plan
  assert {
    condition     = jsondecode(aws_iam_role.this["ebs-csi"].assume_role_policy).Statement[0].Condition.StringEquals["oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLE:sub"] == "system:serviceaccount:kube-system:ebs-csi-controller-sa"
    error_message = "the trust policy must name the service account"
  }
  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 1
    error_message = "one managed policy expected"
  }
}
