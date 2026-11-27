module "userdata" {
  source = "../eks-userdata"

  is_custom_ami         = var.use_custom_ami
  cluster_name          = var.cluster_name
  cluster_endpoint      = var.cluster_endpoint
  cluster_auth_base64   = var.cluster_auth_b64
  ami_type              = var.ami_id == null ? var.ami_type : "CUSTOM"
  pre_userdata          = var.pre_userdata
  post_userdata         = var.additional_userdata
  kubelet_extra_args    = var.kubelet_extra_args
  kubelet_extra_config  = var.kubelet_extra_config
  bottlerocket_settings = var.bottlerocket_settings
  ca_bundles            = var.ca_bundles
  service_cidr          = var.service_cidr
  bootstrap_labels      = var.labels
  max_pods              = var.max_pods
}

resource "aws_launch_template" "this" {
  count       = var.use_launch_template ? 1 : 0
  name        = var.launch_template_name
  name_prefix = var.launch_template_name == null ? "${var.cluster_name}-${var.node_group_name}" : null

  image_id      = var.use_custom_ami ? coalesce(data.aws_ami.eks_worker[0].image_id) : null
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = var.public_ip
    delete_on_termination       = var.eni_delete
    security_groups = flatten([
      var.worker_security_group_id,
      var.additional_security_group_ids
    ])
  }
  enclave_options {
    enabled = var.enclave_support
  }

  metadata_options {
    http_endpoint               = var.metadata_http_endpoint
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
  }

  key_name  = var.ssh_key
  user_data = module.userdata.userdata

  dynamic "credit_specification" {
    for_each = var.cpu_credits == null ? [] : [var.cpu_credits]
    content {
      cpu_credits = credit_specification.value
    }
  }
  monitoring {
    enabled = var.enable_monitoring
  }
  dynamic "placement" {
    for_each = var.launch_template_placement_group == null ? [] : [var.launch_template_placement_group]
    content {
      tenancy    = var.launch_template_placement_tenancy
      group_name = placement.value
    }
  }

  ebs_optimized = coalesce(var.ebs_optimized, !contains(local.ebs_optimized_not_supported, var.instance_type))

  block_device_mappings {
    device_name = coalesce(var.root_block_device_name, data.aws_ami.eks_worker[0].root_device_name)
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      iops                  = var.root_iops
      throughput            = var.root_throughput
      encrypted             = var.encrypted
      kms_key_id            = var.encrypted ? data.aws_kms_key.ebs[0].arn : null
      delete_on_termination = true
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.additional_ebs_volumes
    content {
      device_name = block_device_mappings.value.block_device_name

      ebs {
        volume_size           = block_device_mappings.value["volume_size"]
        volume_type           = block_device_mappings.value["volume_type"]
        iops                  = block_device_mappings.value["iops"]
        throughput            = block_device_mappings.value["throughput"]
        encrypted             = var.encrypted
        kms_key_id            = var.encrypted ? data.aws_kms_key.ebs[0].arn : null
        delete_on_termination = block_device_mappings.value["delete_on_termination"]
      }
    }
  }

  dynamic "tag_specifications" {
    for_each = {
      for type in local.lt_resources_to_tag : type => data.aws_default_tags.this if var.enable_tag_specifications
    }
    content {
      resource_type = tag_specifications.key

      tags = merge(
        tag_specifications.value.tags,
        var.tags,
        var.mng_tags,
        {
          "Name" = format("%s-%s-eks_mng", var.cluster_name, var.node_group_name)
        }
      )
    }
  }

  tags = merge(
    var.tags,
    var.mng_tags,
  )

  lifecycle {
    create_before_destroy = true
  }
}