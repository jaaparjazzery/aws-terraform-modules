resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  drop_invalid_header_fields = var.drop_invalid_header_fields
  idle_timeout              = var.idle_timeout

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.alb_name
    }
  )
}

resource "aws_lb_target_group" "main" {
  for_each = var.target_groups

  name     = each.value.name
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id

  target_type = each.value.target_type

  deregistration_delay = each.value.deregistration_delay

  health_check {
    enabled             = each.value.health_check.enabled
    path                = each.value.health_check.path
    protocol            = each.value.health_check.protocol
    matcher             = each.value.health_check.matcher
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
  }

  stickiness {
    type            = each.value.stickiness.type
    cookie_duration = each.value.stickiness.cookie_duration
    enabled         = each.value.stickiness.enabled
  }

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  count             = var.enable_http_listener ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type = var.http_redirect_to_https ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.http_redirect_to_https ? [1] : []
      content {
        port        = var.https_port
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.http_redirect_to_https ? null : (var.default_target_group_key != null ? aws_lb_target_group.main[var.default_target_group_key].arn : null)
  }

  tags = var.tags
}

resource "aws_lb_listener" "https" {
  count             = var.enable_https_listener ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.default_target_group_key != null ? aws_lb_target_group.main[var.default_target_group_key].arn : null
  }

  tags = var.tags
}

resource "aws_lb_listener_certificate" "additional" {
  for_each = var.enable_https_listener ? var.additional_certificates : {}

  listener_arn    = aws_lb_listener.https[0].arn
  certificate_arn = each.value
}

resource "aws_lb_listener_rule" "host_based" {
  for_each = var.listener_rules

  listener_arn = var.enable_https_listener ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn
  priority     = each.value.priority

  action {
    type             = each.value.action_type
    target_group_arn = each.value.action_type == "forward" ? aws_lb_target_group.main[each.value.target_group_key].arn : null

    dynamic "redirect" {
      for_each = each.value.action_type == "redirect" ? [each.value.redirect_config] : []
      content {
        protocol    = redirect.value.protocol
        port        = redirect.value.port
        host        = redirect.value.host
        path        = redirect.value.path
        query       = redirect.value.query
        status_code = redirect.value.status_code
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.action_type == "fixed-response" ? [each.value.fixed_response_config] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      dynamic "host_header" {
        for_each = lookup(condition.value, "host_header", null) != null ? [condition.value.host_header] : []
        content {
          values = host_header.value
        }
      }

      dynamic "path_pattern" {
        for_each = lookup(condition.value, "path_pattern", null) != null ? [condition.value.path_pattern] : []
        content {
          values = path_pattern.value
        }
      }

      dynamic "http_request_method" {
        for_each = lookup(condition.value, "http_request_method", null) != null ? [condition.value.http_request_method] : []
        content {
          values = http_request_method.value
        }
      }

      dynamic "source_ip" {
        for_each = lookup(condition.value, "source_ip", null) != null ? [condition.value.source_ip] : []
        content {
          values = source_ip.value
        }
      }
    }
  }
}

resource "aws_lb_target_group_attachment" "static" {
  for_each = var.target_attachments

  target_group_arn = aws_lb_target_group.main[each.value.target_group_key].arn
  target_id        = each.value.target_id
  port             = each.value.port
}
