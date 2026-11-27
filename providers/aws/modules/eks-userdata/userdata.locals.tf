locals {
  family = startswith(var.ami_type, "BOTTLEROCKET") ? "bottlerocket" : "al2023"

  kubelet_config = merge(
    var.kubelet_extra_config,
    var.max_pods != null ? { maxPods = var.max_pods } : {}
  )

  # The NodeConfig of nodeadm (AL2023), built as an object and written with yamlencode. With a custom AMI it carries
  # the cluster connection and is the only NodeConfig; on the EKS image only the kubelet part, which nodeadm merges with
  # the NodeConfig EKS writes (which of the two wins for maxPods is still to be verified on a real node).
  nodeconfig_spec = merge(
    var.is_custom_ami ? {
      cluster = {
        name                 = var.cluster_name
        apiServerEndpoint    = var.cluster_endpoint
        certificateAuthority = var.cluster_auth_base64
        cidr                 = var.service_cidr
      }
    } : {},
    length(local.kubelet_config) > 0 || length(var.kubelet_extra_args) > 0 ? {
      kubelet = merge(
        length(local.kubelet_config) > 0 ? { config = local.kubelet_config } : {},
        length(var.kubelet_extra_args) > 0 ? { flags = var.kubelet_extra_args } : {}
      )
    } : {}
  )
  nodeconfig = length(local.nodeconfig_spec) > 0 ? {
    apiVersion = "node.eks.aws/v1alpha1"
    kind       = "NodeConfig"
    spec       = local.nodeconfig_spec
  } : null

  userdata = local.family == "al2023" ? templatefile("${path.module}/templates/al2023/userdata.tftpl", {
    pre_userdata    = var.pre_userdata
    ca_bundles      = var.ca_bundles
    nodeconfig_yaml = local.nodeconfig == null ? null : yamlencode(local.nodeconfig)
    post_userdata   = var.post_userdata
    }) : templatefile("${path.module}/templates/bottlerocket/userdata.tftpl", {
    is_custom_ami         = var.is_custom_ami
    cluster_name          = var.cluster_name
    cluster_endpoint      = var.cluster_endpoint
    cluster_auth_base64   = var.cluster_auth_base64
    cluster_dns_ip        = var.service_cidr == null ? null : cidrhost(var.service_cidr, 10)
    max_pods              = var.max_pods
    bootstrap_labels      = var.bootstrap_labels
    bottlerocket_settings = var.bottlerocket_settings
    ca_bundles            = var.ca_bundles
  })
}
