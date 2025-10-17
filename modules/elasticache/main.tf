# modules/elasticache/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "this" {
  count = var.create_subnet_group ? 1 : 0

  name       = var.subnet_group_name
  subnet_ids = var.subnet_ids

  tags = var.tags
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name   = var.parameter_group_name
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = var.tags
}

# ElastiCache Replication Group (Redis)
resource "aws_elasticache_replication_group" "redis" {
  count = var.engine == "redis" ? 1 : 0

  replication_group_id       = var.replication_group_id
  description                = var.description
  engine                     = "redis"
  engine_version             = var.engine_version
  node_type                  = var.node_type
  num_cache_clusters         = var.cluster_mode_enabled ? null : var.num_cache_clusters
  parameter_group_name       = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].name : var.parameter_group_name
  port                       = var.port
  subnet_group_name          = var.create_subnet_group ? aws_elasticache_subnet_group.this[0].name : var.subnet_group_name
  security_group_ids         = var.security_group_ids
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.auth_token
  kms_key_id                 = var.kms_key_id
  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window            = var.snapshot_window
  maintenance_window         = var.maintenance_window
  notification_topic_arn     = var.notification_topic_arn
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  data_tiering_enabled       = var.data_tiering_enabled
  
  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery_configuration
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  apply_immediately = var.apply_immediately

  tags = var.tags
}

# ElastiCache Cluster (Memcached)
resource "aws_elasticache_cluster" "memcached" {
  count = var.engine == "memcached" ? 1 : 0

  cluster_id           = var.cluster_id
  engine               = "memcached"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].name : var.parameter_group_name
  port                 = var.port
  subnet_group_name    = var.create_subnet_group ? aws_elasticache_subnet_group.this[0].name : var.subnet_group_name
  security_group_ids   = var.security_group_ids
  az_mode              = var.az_mode
  preferred_availability_zones = var.preferred_availability_zones
  maintenance_window   = var.maintenance_window
  notification_topic_arn = var.notification_topic_arn
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  
  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery_configuration
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  apply_immediately = var.apply_immediately

  tags = var.tags
}

# ElastiCache User (Redis)
resource "aws_elasticache_user" "this" {
  for_each = var.engine == "redis" && var.users != null ? var.users : {}

  user_id       = each.key
  user_name     = each.value.user_name
  access_string = each.value.access_string
  engine        = "REDIS"
  passwords     = lookup(each.value, "passwords", null)

  tags = var.tags
}

# ElastiCache User Group (Redis)
resource "aws_elasticache_user_group" "this" {
  count = var.engine == "redis" && var.user_group_id != null ? 1 : 0

  engine        = "REDIS"
  user_group_id = var.user_group_id
  user_ids      = var.user_ids

  tags = var.tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.engine == "redis" ? var.replication_group_id : var.cluster_id}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "ElastiCache CPU utilization too high"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = var.engine == "redis" ? {
    ReplicationGroupId = var.replication_group_id
  } : {
    CacheClusterId = var.cluster_id
  }
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  count = var.create_alarms && var.engine == "redis" ? 1 : 0

  alarm_name          = "${var.replication_group_id}-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_description   = "ElastiCache available memory too low"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    ReplicationGroupId = var.replication_group_id
  }
}