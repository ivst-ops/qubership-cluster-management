# The component with node groups and add-ons, planned against a mocked AWS provider.
mock_provider "aws" {
  mock_resource "aws_eks_cluster" {
    defaults = {
      version               = "1.34"
      endpoint              = "https://example.invalid"
      certificate_authority = [{ data = "Q0E=" }]
      identity              = [{ oidc = [{ issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE" }] }]
    }
  }
  mock_resource "aws_launch_template" {
    defaults = { id = "lt-0123456789abcdef0", latest_version = 1 }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::000000000000:role/mock" }
  }
  mock_resource "aws_iam_user" {
    defaults = { arn = "arn:aws:iam::000000000000:user/t-s-kubectl" }
  }
  mock_resource "aws_iam_openid_connect_provider" {
    defaults = { arn = "arn:aws:iam::000000000000:oidc-provider/mock" }
  }
  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:us-east-1:000000000000:key/mock" }
  }
  mock_data "aws_ami" {
    defaults = { image_id = "ami-00000000000000000", root_device_name = "/dev/xvda" }
  }
  mock_data "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:us-east-1:000000000000:key/ebs" }
  }
  mock_data "aws_default_tags" {
    defaults = { tags = {} }
  }
}

variables {
  stage        = "staging"
  environment  = "t-s"
  subnet_ids   = { a = "subnet-a", b = "subnet-b" }
  service_cidr = "10.100.0.0/16"
  node_group_defaults = {
    max_pods       = 110
    kubelet_config = { kubeReserved = { cpu = "200m", memory = "2250Mi" } }
  }
  node_groups = {
    general = { desired_size = 2, min_size = 2, max_size = 2, subnets = ["a"] }
    data = {
      instance_type      = "r6i.2xlarge"
      labels             = { pool = "data" }
      taints             = [{ key = "pool", value = "data", effect = "NO_SCHEDULE" }]
      additional_volumes = [{ block_device_name = "/dev/xvdb", volume_size = 200 }]
    }
  }
  addons       = { vpc-cni = { before_nodes = true }, aws-ebs-csi-driver = { irsa_role = "ebs-csi" } }
  irsa_enabled = true
  irsa_roles = {
    ebs-csi = { namespace = "kube-system", service_account = "ebs-csi-controller-sa", policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"] }
  }
  access_entries = { ops = { principal_arn = "arn:aws:iam::000000000000:role/ops" } }
}

run "groups_take_defaults_and_overrides" {
  command = apply
  assert {
    condition     = module.node_groups["general"].update_settings.max_unavailable == 1 && !module.node_groups["general"].update_settings.auto_repair && !module.node_groups["general"].update_settings.force_update_version
    error_message = "safe defaults: one node at a time, no forced update, no automatic repair"
  }
  assert {
    condition     = module.node_groups["general"].ami_info[0].image_id == "ami-00000000000000000"
    error_message = "the general group did not plan"
  }
  assert {
    condition     = length(aws_iam_role_policy_attachment.nodes) == 3
    error_message = "the node role needs the worker, CNI and ECR read policies"
  }
  assert {
    condition     = aws_eks_cluster.main.access_config[0].authentication_mode == "API"
    error_message = "access entries only"
  }
  assert {
    condition     = length(aws_iam_user.kubectl) == 0 && length(aws_eks_access_entry.this) == 1
    error_message = "no static-key user outside the lab; one access entry for ops"
  }
}

run "update_settings_are_overridden_per_group" {
  command = plan
  variables {
    node_groups = {
      general = { max_unavailable_percentage = 25, force_update_version = true, auto_repair = true }
    }
  }
  assert {
    condition     = module.node_groups["general"].update_settings.max_unavailable_percentage == 25 && module.node_groups["general"].update_settings.max_unavailable == null
    error_message = "the percentage must replace the count"
  }
  assert {
    condition     = module.node_groups["general"].update_settings.force_update_version && module.node_groups["general"].update_settings.auto_repair
    error_message = "stack overrides of force update and repair are lost"
  }
}

run "no_groups_no_node_role" {
  command = plan
  variables {
    node_groups = {}
  }
  assert {
    condition     = length(aws_iam_role.nodes) == 0
    error_message = "no node role without node groups"
  }
}

run "lab_user_gets_admin_entry" {
  command = plan
  variables {
    local_endpoint = "http://floci:4566"
    node_groups    = {}
  }
  assert {
    condition     = length(aws_iam_user.kubectl) == 1 && aws_eks_access_policy_association.this["lab"].policy_arn == "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    error_message = "the lab user needs its access entry with the cluster-admin policy"
  }
}
