resource "aws_security_group" "nexus" {
  name        = "${var.environment}-nexus"
  description = "Network access for the Nexus instance"
  vpc_id      = var.vpc_id
}

# Accepted until 2027-02-17 (baseline of the quality gate): Nexus reaches upstream mirrors; restrict once the offline network model is fixed.
#trivy:ignore:AWS-0104:exp:2027-02-17
resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.nexus.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_instance" "nexus" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.nexus.id]

  # IMDSv2 only: a token is required for the instance metadata (SSRF cannot read the instance role credentials).
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
    # default_tags do not reach the root volume.
    tags = local.cost_tags
  }

  tags = {
    Name = "${var.environment}-nexus"
    Role = "nexus"
  }

  user_data = replace(templatefile("${path.module}/user-data.sh.tftpl", {
    nexus_version = var.nexus_version
  }), "\r\n", "\n")

  user_data_replace_on_change = true

  depends_on = [
    aws_vpc_security_group_egress_rule.outbound
  ]
}


resource "aws_vpc_security_group_ingress_rule" "nexus_http" {
  security_group_id = aws_security_group.nexus.id

  ip_protocol = "tcp"
  from_port   = 8081
  to_port     = 8081
  cidr_ipv4   = "0.0.0.0/0"
}
