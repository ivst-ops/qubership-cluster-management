# The user data of the node groups: structure of the NodeConfig (kubelet settings), not only its text.
variables {
  cluster_name = "spike"
  max_pods     = 58
  kubelet_extra_config = {
    kubeReserved   = { cpu = "200m", memory = "1210Mi" }
    systemReserved = { cpu = "300m", memory = "1280Mi" }
    evictionHard   = { "memory.available" = "500Mi" }
  }
  ca_bundles = ["-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----"]
}

run "eks_image_gets_kubelet_part_only" {
  command = plan
  assert {
    condition     = output.nodeconfig.kind == "NodeConfig" && output.nodeconfig.spec.kubelet.config.maxPods == 58
    error_message = "maxPods missing from the NodeConfig"
  }
  assert {
    condition     = output.nodeconfig.spec.kubelet.config.kubeReserved.memory == "1210Mi"
    error_message = "kubeReserved missing from the NodeConfig"
  }
  assert {
    condition     = !contains(keys(output.nodeconfig.spec), "cluster")
    error_message = "the cluster connection belongs only to a custom AMI"
  }
  assert {
    # The NodeConfig part of the MIME text is the YAML of the object.
    condition     = yamldecode(split("--==BOUNDARY==", split("Content-Type: application/node.eks.aws\n\n---\n", output.userdata_decoded)[1])[0]).spec.kubelet.config.maxPods == 58
    error_message = "the rendered NodeConfig does not decode to the object"
  }
  assert {
    condition     = strcontains(output.userdata_decoded, "BEGIN CERTIFICATE")
    error_message = "CA bundle missing"
  }
}

run "custom_ami_gets_cluster_and_service_cidr" {
  command = plan
  variables {
    ami_type            = "CUSTOM"
    is_custom_ami       = true
    cluster_endpoint    = "https://example.invalid"
    cluster_auth_base64 = "Q0E="
    service_cidr        = "10.100.0.0/16"
  }
  assert {
    condition     = output.nodeconfig.spec.cluster.cidr == "10.100.0.0/16" && output.nodeconfig.spec.cluster.name == "spike"
    error_message = "the cluster connection of a custom AMI is incomplete"
  }
}

run "custom_ami_without_service_cidr_fails" {
  command = plan
  variables {
    is_custom_ami       = true
    cluster_endpoint    = "https://example.invalid"
    cluster_auth_base64 = "Q0E="
  }
  expect_failures = [output.userdata]
}

run "flags_alone_render_a_nodeconfig" {
  command = plan
  variables {
    max_pods             = null
    kubelet_extra_config = {}
    kubelet_extra_args   = ["--node-labels=pool=data"]
  }
  assert {
    condition     = output.nodeconfig.spec.kubelet.flags[0] == "--node-labels=pool=data" && !contains(keys(output.nodeconfig.spec.kubelet), "config")
    error_message = "kubelet flags without a kubelet config are lost"
  }
}

run "nothing_to_configure_means_no_nodeconfig" {
  command = plan
  variables {
    max_pods             = null
    kubelet_extra_config = {}
  }
  assert {
    condition     = output.nodeconfig == null && !strcontains(output.userdata_decoded, "NodeConfig")
    error_message = "empty NodeConfig rendered"
  }
}

run "bottlerocket_uses_toml_and_the_service_cidr" {
  command = plan
  variables {
    ami_type            = "BOTTLEROCKET_x86_64"
    is_custom_ami       = true
    cluster_endpoint    = "https://example.invalid"
    cluster_auth_base64 = "Q0E="
    service_cidr        = "10.100.0.0/16"
  }
  assert {
    condition     = output.nodeconfig == null && strcontains(output.userdata_decoded, "settings.kubernetes.cluster-dns-ip = '10.100.0.10'") && strcontains(output.userdata_decoded, "settings.kubernetes.max-pods = 58")
    error_message = "Bottlerocket settings do not follow the service CIDR or maxPods"
  }
}

run "unknown_ami_type_is_rejected" {
  command = plan
  variables {
    ami_type = "AL2_x86_64"
  }
  expect_failures = [var.ami_type]
}
