# modules/route53/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Route53 Hosted Zone
resource "aws_route53_zone" "this" {
  for_each = var.hosted_zones

  name              = each.key
  comment           = lookup(each.value, "comment", null)
  force_destroy     = lookup(each.value, "force_destroy", false)
  delegation_set_id = lookup(each.value, "delegation_set_id", null)

  dynamic "vpc" {
    for_each = lookup(each.value, "vpcs", [])
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = lookup(vpc.value, "vpc_region", null)
    }
  }

  tags = var.tags
}

# Route53 Records
resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = aws_route53_zone.this[each.value.zone_name].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = lookup(each.value, "ttl", null)
  records = lookup(each.value, "records", null)

  set_identifier = lookup(each.value, "set_identifier", null)
  health_check_id = lookup(each.value, "health_check_id", null)
  multivalue_answer_routing_policy = lookup(each.value, "multivalue_answer_routing_policy", null)
  allow_overwrite = lookup(each.value, "allow_overwrite", false)

  dynamic "alias" {
    for_each = lookup(each.value, "alias", null) != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = lookup(alias.value, "evaluate_target_health", false)
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = lookup(each.value, "weighted_routing_policy", null) != null ? [each.value.weighted_routing_policy] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  dynamic "latency_routing_policy" {
    for_each = lookup(each.value, "latency_routing_policy", null) != null ? [each.value.latency_routing_policy] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = lookup(each.value, "geolocation_routing_policy", null) != null ? [each.value.geolocation_routing_policy] : []
    content {
      continent   = lookup(geolocation_routing_policy.value, "continent", null)
      country     = lookup(geolocation_routing_policy.value, "country", null)
      subdivision = lookup(geolocation_routing_policy.value, "subdivision", null)
    }
  }

  dynamic "failover_routing_policy" {
    for_each = lookup(each.value, "failover_routing_policy", null) != null ? [each.value.failover_routing_policy] : []
    content {
      type = failover_routing_policy.value.type
    }
  }

  dynamic "cidr_routing_policy" {
    for_each = lookup(each.value, "cidr_routing_policy", null) != null ? [each.value.cidr_routing_policy] : []
    content {
      collection_id = cidr_routing_policy.value.collection_id
      location_name = cidr_routing_policy.value.location_name
    }
  }
}

# Route53 Health Check
resource "aws_route53_health_check" "this" {
  for_each = var.health_checks

  type                            = each.value.type
  ip_address                      = lookup(each.value, "ip_address", null)
  port                            = lookup(each.value, "port", null)
  resource_path                   = lookup(each.value, "resource_path", null)
  fqdn                            = lookup(each.value, "fqdn", null)
  request_interval                = lookup(each.value, "request_interval", 30)
  failure_threshold               = lookup(each.value, "failure_threshold", 3)
  measure_latency                 = lookup(each.value, "measure_latency", false)
  invert_healthcheck              = lookup(each.value, "invert_healthcheck", false)
  disabled                        = lookup(each.value, "disabled", false)
  enable_sni                      = lookup(each.value, "enable_sni", true)
  child_healthchecks              = lookup(each.value, "child_healthchecks", null)
  child_health_threshold          = lookup(each.value, "child_health_threshold", null)
  cloudwatch_alarm_name           = lookup(each.value, "cloudwatch_alarm_name", null)
  cloudwatch_alarm_region         = lookup(each.value, "cloudwatch_alarm_region", null)
  insufficient_data_health_status = lookup(each.value, "insufficient_data_health_status", null)
  reference_name                  = lookup(each.value, "reference_name", null)
  search_string                   = lookup(each.value, "search_string", null)

  tags = var.tags
}

# Route53 Query Log
resource "aws_route53_query_log" "this" {
  for_each = var.query_logs

  zone_id                  = aws_route53_zone.this[each.key].zone_id
  cloudwatch_log_group_arn = each.value.cloudwatch_log_group_arn
}

# Route53 Traffic Policy
resource "aws_route53_traffic_policy" "this" {
  for_each = var.traffic_policies

  name     = each.key
  comment  = lookup(each.value, "comment", null)
  document = each.value.document
}

# Route53 Traffic Policy Instance
resource "aws_route53_traffic_policy_instance" "this" {
  for_each = var.traffic_policy_instances

  name                   = each.value.name
  traffic_policy_id      = aws_route53_traffic_policy.this[each.value.traffic_policy_name].id
  traffic_policy_version = each.value.traffic_policy_version
  hosted_zone_id         = aws_route53_zone.this[each.value.zone_name].zone_id
  ttl                    = each.value.ttl
}

# Route53 Delegation Set
resource "aws_route53_delegation_set" "this" {
  for_each = var.delegation_sets

  reference_name = each.key
}

# Route53 VPC Association Authorization
resource "aws_route53_vpc_association_authorization" "this" {
  for_each = var.vpc_association_authorizations

  zone_id = aws_route53_zone.this[each.value.zone_name].zone_id
  vpc_id  = each.value.vpc_id
}

# Route53 Zone Association
resource "aws_route53_zone_association" "this" {
  for_each = var.zone_associations

  zone_id = aws_route53_zone.this[each.value.zone_name].zone_id
  vpc_id  = each.value.vpc_id
}

# CloudWatch Alarms for Route53 Health Checks
resource "aws_cloudwatch_metric_alarm" "health_check" {
  for_each = var.create_health_check_alarms ? var.health_checks : {}

  alarm_name          = "${each.key}-health-check-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Route53 health check failed"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    HealthCheckId = aws_route53_health_check.this[each.key].id
  }
}