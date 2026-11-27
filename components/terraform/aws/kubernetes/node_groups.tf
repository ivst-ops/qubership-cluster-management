# Managed node groups from the stack catalog through providers/aws/modules/eks-node-group. The kubelet settings
# (maxPods, reservations, eviction) go into the NodeConfig of the launch template; dedicated volumes for the container
# runtime and the kubelet are additional EBS volumes. Defaults of node_group_defaults apply to every group.
locals {
  node_groups = {
    for k, g in var.node_groups : k => {
      instance_type      = coalesce(g.instance_type, var.node_group_defaults.instance_type)
      min_size           = coalesce(g.min_size, var.node_group_defaults.min_size)
      max_size           = coalesce(g.max_size, var.node_group_defaults.max_size)
      desired_size       = coalesce(g.desired_size, var.node_group_defaults.desired_size)
      capacity_type      = coalesce(g.capacity_type, var.node_group_defaults.capacity_type)
      root_volume_size   = coalesce(g.root_volume_size, var.node_group_defaults.root_volume_size)
      max_unavailable    = coalesce(g.max_unavailable, var.node_group_defaults.max_unavailable)
      auto_repair        = coalesce(g.auto_repair, var.node_group_defaults.auto_repair)
      force_update       = coalesce(g.force_update_version, var.node_group_defaults.force_update_version)
      max_unavailable_pc = g.max_unavailable_percentage != null ? g.max_unavailable_percentage : var.node_group_defaults.max_unavailable_percentage
      ami_type           = coalesce(g.ami_type, var.node_group_defaults.ami_type)
      use_custom_ami     = coalesce(g.use_custom_ami, var.node_group_defaults.use_custom_ami)
      ami_release        = g.ami_release_version != null ? g.ami_release_version : var.node_group_defaults.ami_release_version
      max_pods           = g.max_pods != null ? g.max_pods : var.node_group_defaults.max_pods
      kubelet_config     = g.kubelet_config != null ? g.kubelet_config : var.node_group_defaults.kubelet_config
      subnets            = g.subnets
      labels             = g.labels
      taints             = g.taints
      additional_volumes = g.additional_volumes
    }
  }
}

resource "aws_iam_role" "nodes" {
  count = length(var.node_groups) > 0 ? 1 : 0

  name = "${var.environment}-eks-nodes"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = length(var.node_groups) > 0 ? toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]) : toset([])

  role       = aws_iam_role.nodes[0].name
  policy_arn = each.value
}

module "node_groups" {
  source   = "../../../../providers/aws/modules/eks-node-group"
  for_each = local.node_groups

  cluster_name             = aws_eks_cluster.main.name
  cluster_version          = aws_eks_cluster.main.version
  cluster_endpoint         = aws_eks_cluster.main.endpoint
  cluster_auth_b64         = aws_eks_cluster.main.certificate_authority[0].data
  service_cidr             = try(aws_eks_cluster.main.kubernetes_network_config[0].service_ipv4_cidr, var.service_cidr)
  aws_region               = var.region
  vpc_id                   = aws_eks_cluster.main.vpc_config[0].vpc_id
  subnet_ids               = length(each.value.subnets) > 0 ? [for s in each.value.subnets : var.subnet_ids[s]] : values(var.subnet_ids)
  worker_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  iam_role_arn             = aws_iam_role.nodes[0].arn

  node_group_name               = "${var.environment}-${each.key}"
  ami_type                      = each.value.ami_type
  use_custom_ami                = each.value.use_custom_ami
  ami_release_version           = each.value.ami_release
  instance_type                 = each.value.instance_type
  mng_min_size                  = each.value.min_size
  mng_max_size                  = each.value.max_size
  mng_desired_size              = each.value.desired_size
  capacity_type                 = each.value.capacity_type
  labels                        = each.value.labels
  taint_install                 = length(each.value.taints) > 0
  taints                        = each.value.taints
  root_volume_size              = each.value.root_volume_size
  additional_ebs_volumes        = each.value.additional_volumes
  max_pods                      = each.value.max_pods
  kubelet_extra_config          = each.value.kubelet_config
  update_config_max_unavailable = each.value.max_unavailable
  # The module takes the percentage over the count when both are set.
  update_config_max_unavailable_percentage = each.value.max_unavailable_pc
  force_update_version                     = each.value.force_update
  node_repair_config                       = { enabled = each.value.auto_repair }

  depends_on = [aws_iam_role_policy_attachment.nodes, module.addons_before_nodes]
}
