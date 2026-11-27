# Representative inputs for `task lint:trivy`: one node group, so that the launch template and its volumes are scanned.
stage       = "staging"
environment = "t-s"
subnet_ids  = { a = "subnet-a" }
node_groups = {
  general = { additional_volumes = [{ block_device_name = "/dev/xvdb", volume_size = 100 }] }
}
service_cidr = "10.100.0.0/16"
