# Customer-managed key for the Kubernetes secrets of the cluster (aws_eks_cluster.main.encryption_config).
resource "aws_kms_key" "secrets" {
  description         = "${var.environment} EKS secrets"
  enable_key_rotation = true
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.environment}-eks-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# The cluster role encrypts and decrypts with the key.
resource "aws_iam_role_policy" "cluster_secrets_key" {
  name = "${var.environment}-eks-secrets-key"
  role = aws_iam_role.cluster.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ListGrants", "kms:DescribeKey"]
      Resource = aws_kms_key.secrets.arn
    }]
  })
}
