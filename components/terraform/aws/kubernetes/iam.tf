resource "aws_iam_role" "cluster" {
  name = "${var.environment}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Only the local lab signs in with an IAM user and static keys (local/lab.sh creates the keys); a real stack names its
# operator and runner roles in access_entries: static keys are an exception.
resource "aws_iam_user" "kubectl" {
  count = var.local_endpoint != null ? 1 : 0

  name          = "${var.environment}-kubectl"
  force_destroy = true
}

moved {
  from = aws_iam_user.kubectl
  to   = aws_iam_user.kubectl[0]
}
