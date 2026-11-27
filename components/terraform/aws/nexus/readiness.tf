data "external" "nexus_endpoint" {
  count = var.nexus_wait_for_ready && var.local_endpoint != null && var.nexus_readiness_url == null ? 1 : 0

  # JSON {"instance_id"} on stdin, {"url"} on stdout; the lab sidecar looks up the published port.
  program = ["bash", "${path.module}/../../../../local/lab.sh", "nexus-endpoint-json"]
  query = {
    instance_id = aws_instance.nexus.id
  }

  # Floci publishes the port after the instance and its ingress rule exist.
  depends_on = [
    aws_instance.nexus,
    aws_vpc_security_group_ingress_rule.nexus_http
  ]
}

locals {
  # Real AWS: derive the URL from aws_instance.nexus.public_ip, falling back to
  # aws_instance.nexus.private_ip. The OpenTofu runner must be able to reach it.
  # Floci (local lab): external discovers the published host port during
  # the same apply. No endpoint script is invoked for real AWS.
  nexus_readiness_endpoint = var.nexus_readiness_url != null ? var.nexus_readiness_url : (
    var.local_endpoint != null ? (
      var.nexus_wait_for_ready ? data.external.nexus_endpoint[0].result.url : null
    ) : "http://${coalesce(aws_instance.nexus.public_ip, aws_instance.nexus.private_ip)}:8081/service/rest/v1/status/writable"
  )
}

data "http" "nexus_ready" {
  count = var.nexus_wait_for_ready ? 1 : 0

  url                = local.nexus_readiness_endpoint
  request_timeout_ms = 5000

  # Up to 20 minutes: the user data downloads the 500 MB Nexus archive first, about 9 minutes at 1 MB/s.
  retry {
    attempts     = 120
    min_delay_ms = 10000
    max_delay_ms = 10000
  }

  depends_on = [
    aws_instance.nexus,
    aws_vpc_security_group_ingress_rule.nexus_http
  ]

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Nexus readiness endpoint must return HTTP 200."
    }
  }
}
