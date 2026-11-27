# Plan-only tests with a mocked AWS provider: no cloud, no credentials.
mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = { image_id = "ami-00000000000000000", root_device_name = "/dev/xvda" }
  }
  mock_data "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:eu-west-1:000000000000:key/00000000-0000-0000-0000-000000000000" }
  }
  mock_resource "aws_launch_template" {
    defaults = { id = "lt-0123456789abcdef0", latest_version = 1 }
  }
  mock_data "aws_default_tags" {
    defaults = { tags = {} }
  }
}

variables {
  cluster_name             = "spike"
  aws_region               = "eu-west-1"
  vpc_id                   = "vpc-0"
  cluster_auth_b64         = "Q0E="
  cluster_endpoint         = "https://example.invalid"
  cluster_version          = "1.34"
  service_cidr             = "10.100.0.0/16"
  node_group_name          = "p-general"
  iam_role_arn             = "arn:aws:iam::000000000000:role/spike-nodes"
  subnet_ids               = ["subnet-a", "subnet-b"]
  worker_security_group_id = "sg-0"
  instance_type            = "m6i.2xlarge"
  mng_min_size             = 3
  mng_max_size             = 3
  mng_desired_size         = 3
  max_pods                 = 58
  kubelet_extra_config     = { kubeReserved = { cpu = "200m", memory = "1210Mi" } }
  additional_ebs_volumes = [
    { block_device_name = "/dev/xvdb", volume_size = 100, volume_type = "gp3", iops = 3000, throughput = 125, delete_on_termination = true },
  ]
}

run "custom_ami_defaults_follow_the_adrs" {
  command = plan
  assert {
    condition     = aws_eks_node_group.this.update_config[0].max_unavailable == 1
    error_message = "nodes must be updated one at a time by default"
  }
  assert {
    condition     = aws_launch_template.this[0].metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required"
  }
  assert {
    condition     = alltrue([for b in aws_launch_template.this[0].block_device_mappings : b.ebs[0].encrypted == "true"])
    error_message = "all volumes must be encrypted"
  }
  assert {
    condition     = length(aws_launch_template.this[0].block_device_mappings) == 2
    error_message = "root volume plus the dedicated data volume expected"
  }
  assert {
    condition     = aws_launch_template.this[0].image_id == "ami-00000000000000000" && output.eks_ami_type == null
    error_message = "a custom AMI is named by the launch template, not by ami_type"
  }
  assert {
    condition     = yamldecode(split("--==BOUNDARY==", split("Content-Type: application/node.eks.aws\n\n---\n", base64decode(aws_launch_template.this[0].user_data))[1])[0]).spec.cluster.cidr == "10.100.0.0/16" && yamldecode(split("--==BOUNDARY==", split("Content-Type: application/node.eks.aws\n\n---\n", base64decode(aws_launch_template.this[0].user_data))[1])[0]).spec.kubelet.config.maxPods == 58
    error_message = "the NodeConfig of the custom AMI lacks the service CIDR or maxPods"
  }
}

run "eks_image_is_chosen_by_ami_type" {
  command = plan
  variables {
    use_custom_ami = false
    ami_type       = "BOTTLEROCKET_ARM_64"
  }
  assert {
    condition     = aws_launch_template.this[0].image_id == null && output.eks_ami_type == "BOTTLEROCKET_ARM_64"
    error_message = "without a custom AMI EKS must get the ami_type, or it starts its default image"
  }
}

run "max_pods_is_not_forced" {
  command = plan
  variables {
    max_pods             = null
    kubelet_extra_config = {}
  }
  assert {
    condition     = !strcontains(base64decode(aws_launch_template.this[0].user_data), "maxPods")
    error_message = "maxPods must not be written unless the stack sets it"
  }
}
