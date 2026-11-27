data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_security_group" "alb" {
  name        = "${var.environment}-argocd-alb"
  description = "Network access for the Argo CD ALB"
  vpc_id      = var.vpc_id
}

# HTTPS entry, only with a certificate.
resource "aws_vpc_security_group_ingress_rule" "https" {
  count = var.certificate_arn != null ? 1 : 0

  security_group_id = aws_security_group.alb.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.alb.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"
}


# Accepted until 2027-02-17: public by design, the ALB publishes the stack UIs to the operators.
#trivy:ignore:AWS-0053:exp:2027-02-17
resource "aws_lb" "argocd" {
  name               = "${var.environment}-argocd"
  internal           = false
  load_balancer_type = "application"

  drop_invalid_header_fields = true

  security_groups = [aws_security_group.alb.id]
  subnets         = values(var.subnet_ids)

}


data "aws_instance" "node" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  filter {
    name   = "tag:eks:cluster-name"
    values = ["${var.environment}-eks"]
  }
}


# Without certificate_arn the ALB serves plain HTTP; with it, HTTP only redirects to the HTTPS listener below.
# Accepted until 2027-02-17: no certificate configured (certificate_arn is null), so plain HTTP.
#trivy:ignore:AWS-0054:exp:2027-02-17
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.argocd.arn

  protocol = "HTTP"
  port     = 80

  dynamic "default_action" {
    for_each = var.certificate_arn == null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.argocd.arn
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn != null ? [1] : []
    content {
      type = "redirect"
      redirect {
        protocol    = "HTTPS"
        port        = "443"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.argocd.arn

  protocol        = "HTTPS"
  port            = 443
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd.arn
  }
}

locals {
  # The host rules (Argo CD, Kiali, Headlamp, MinIO) live on the listener that serves the traffic.
  rules_listener_arn = var.certificate_arn != null ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}