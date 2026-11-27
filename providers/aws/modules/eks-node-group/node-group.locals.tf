locals {

  ebs_optimized_not_supported = [
    "c1.medium",
    "c3.8xlarge",
    "c3.large",
    "c5d.12xlarge",
    "c5d.24xlarge",
    "c5d.metal",
    "cc2.8xlarge",
    "cr1.8xlarge",
    "g2.8xlarge",
    "g4dn.metal",
    "hs1.8xlarge",
    "i2.8xlarge",
    "m1.medium",
    "m1.small",
    "m2.xlarge",
    "m3.large",
    "m3.medium",
    "m5ad.16xlarge",
    "m5ad.8xlarge",
    "m5dn.metal",
    "m5n.metal",
    "r3.8xlarge",
    "r3.large",
    "r5ad.16xlarge",
    "r5ad.8xlarge",
    "r5dn.metal",
    "r5n.metal",
    "t1.micro",
    "t2.2xlarge",
    "t2.large",
    "t2.medium",
    "t2.micro",
    "t2.nano",
    "t2.small",
    "t2.xlarge"
  ]

  ami_release_version_regex = var.ami_release_version == null ? "v*" : var.ami_release_version
  ami_format_map = {
    "AL2023_x86_64_STANDARD" = format("amazon-eks-node-al2023-x86_64-standard-%s-%s", var.cluster_version, local.ami_release_version_regex)
    "AL2023_ARM_64_STANDARD" = format("amazon-eks-node-al2023-arm64-standard-%s-%s", var.cluster_version, local.ami_release_version_regex)
    "BOTTLEROCKET_x86_64"    = format("bottlerocket-aws-k8s-%s-x86_64-%s", var.cluster_version, local.ami_release_version_regex)
    "BOTTLEROCKET_ARM_64"    = format("bottlerocket-aws-k8s-%s-aarch64-%s", var.cluster_version, local.ami_release_version_regex)
  }

  lt_resources_to_tag = ["instance", "volume", "network-interface"]

  # AZ filter for aws_subnets discovery: suffix letters become "${var.aws_region}${az}" (e.g. "a" -> us-east-1a).
  # "*" means no AZ restriction (skip availability-zone filter). Do not pass a literal region+AZ here.
  mng_allowed_az_for_subnet_filter = [
    for az in var.mng_allowed_az : "${var.aws_region}${az}"
    if az != "*"
  ]

  # The ami_type sent to EKS: null when the launch template names the image (custom AMI).
  eks_ami_type = var.use_launch_template && var.use_custom_ami ? null : (var.ami_id == null ? var.ami_type : null)
}
