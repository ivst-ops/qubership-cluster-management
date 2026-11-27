resource "aws_eks_cluster" "main" {
  name     = "${var.environment}-eks"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = values(var.subnet_ids)

    # Closed by default: the public endpoint exists only for the CIDRs of public_access_cidrs.
    endpoint_private_access = true
    endpoint_public_access  = length(var.public_access_cidrs) > 0
    public_access_cidrs     = length(var.public_access_cidrs) > 0 ? var.public_access_cidrs : null
  }

  # Kubernetes secrets are encrypted in etcd with a customer-managed key (kms.tf).
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.secrets.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster
  ]

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
