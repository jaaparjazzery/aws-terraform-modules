# modules/apigateway/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "this" {
  count = var.api_type == "REST" ? 1 : 0

  name        = var.name
  description = var.description

  endpoint_configuration {
    types = var.endpoint_types
    vpc_endpoint_ids = var.vpc_endpoint_ids
  }

  binary_media_types = var.binary_media_types
  minimum_compression_size = var.minimum_compression_size
  api_key_source = var.api_key_source
  disable_execute_api_endpoint = var.disable_execute_api_endpoint

  dynamic "policy" {
    for_each = var.policy != null ? [1] : []
    content {
      policy = var.policy
    }
  }

  tags = var.tags
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "this" {
  count = var.api_type == "HTTP" || var.api_type == "WEBSOCKET" ? 1 : 0

  name          = var.name
  description   = var.description
  protocol_type = var.api_type
  version       = var.api_version
  route_selection_expression = var.route_selection_expression
  api_key_selection_expression = var.api_key_selection_expression
  disable_execute_api_endpoint = var.disable_execute_api_endpoint

  dynamic "cors_configuration" {
    for_each = var.cors_configuration != null ? [var.cors_configuration] : []
    content {
      allow_credentials = lookup(cors_configuration.value, "allow_credentials", false)
      allow_headers     = lookup(cors_configuration.value, "allow_headers", [])
      allow_methods     = lookup(cors_configuration.value, "allow_methods", [])
      allow_origins     = lookup(cors_configuration.value, "allow_origins", [])
      expose_headers    = lookup(cors_configuration.value, "expose_headers", [])
      max_age           = lookup(cors_configuration.value, "max_age", 0)
    }
  }

  tags = var.tags
}

# API Gateway Stage (REST)
resource "aws_api_gateway_stage" "this" {
  count = var.api_type == "REST" ? 1 : 0

  deployment_id = aws_api_gateway_deployment.this[0].id
  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  stage_name    = var.stage_name
  description   = var.stage_description

  cache_cluster_enabled = var.cache_cluster_enabled
  cache_cluster_size    = var.cache_cluster_enabled ? var.cache_cluster_size : null
  xray_tracing_enabled  = var.xray_tracing_enabled

  dynamic "access_log_settings" {
    for_each = var.access_log_settings != null ? [var.access_log_settings] : []
    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }

  variables = var.stage_variables

  tags = var.tags
}

# API Gateway Deployment (REST)
resource "aws_api_gateway_deployment" "this" {
  count = var.api_type == "REST" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this[0].id

  triggers = {
    redeployment = sha1(jsonencode(var.deployment_triggers))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage (HTTP/WebSocket)
resource "aws_apigatewayv2_stage" "this" {
  count = var.api_type == "HTTP" || var.api_type == "WEBSOCKET" ? 1 : 0

  api_id      = aws_apigatewayv2_api.this[0].id
  name        = var.stage_name
  description = var.stage_description
  auto_deploy = var.auto_deploy

  dynamic "access_log_settings" {
    for_each = var.access_log_settings != null ? [var.access_log_settings] : []
    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }

  dynamic "default_route_settings" {
    for_each = var.default_route_settings != null ? [var.default_route_settings] : []
    content {
      data_trace_enabled       = lookup(default_route_settings.value, "data_trace_enabled", false)
      detailed_metrics_enabled = lookup(default_route_settings.value, "detailed_metrics_enabled", false)
      logging_level            = lookup(default_route_settings.value, "logging_level", "OFF")
      throttling_burst_limit   = lookup(default_route_settings.value, "throttling_burst_limit", null)
      throttling_rate_limit    = lookup(default_route_settings.value, "throttling_rate_limit", null)
    }
  }

  stage_variables = var.stage_variables

  tags = var.tags
}

# Custom Domain Name
resource "aws_api_gateway_domain_name" "rest" {
  count = var.api_type == "REST" && var.domain_name != null ? 1 : 0

  domain_name              = var.domain_name
  certificate_arn          = var.certificate_arn
  security_policy          = var.security_policy
  endpoint_configuration {
    types = var.endpoint_types
  }

  tags = var.tags
}

resource "aws_apigatewayv2_domain_name" "http" {
  count = (var.api_type == "HTTP" || var.api_type == "WEBSOCKET") && var.domain_name != null ? 1 : 0

  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = var.endpoint_types[0]
    security_policy = var.security_policy
  }

  tags = var.tags
}

# Base Path Mapping (REST)
resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.api_type == "REST" && var.domain_name != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.this[0].id
  stage_name  = aws_api_gateway_stage.this[0].stage_name
  domain_name = aws_api_gateway_domain_name.rest[0].domain_name
  base_path   = var.base_path
}

# API Mapping (HTTP/WebSocket)
resource "aws_apigatewayv2_api_mapping" "this" {
  count = (var.api_type == "HTTP" || var.api_type == "WEBSOCKET") && var.domain_name != null ? 1 : 0

  api_id      = aws_apigatewayv2_api.this[0].id
  domain_name = aws_apigatewayv2_domain_name.http[0].id
  stage       = aws_apigatewayv2_stage.this[0].id
  api_mapping_key = var.base_path
}

# Usage Plan (REST)
resource "aws_api_gateway_usage_plan" "this" {
  for_each = var.api_type == "REST" ? var.usage_plans : {}

  name        = each.key
  description = lookup(each.value, "description", null)

  api_stages {
    api_id = aws_api_gateway_rest_api.this[0].id
    stage  = aws_api_gateway_stage.this[0].stage_name
  }

  quota_settings {
    limit  = lookup(each.value, "quota_limit", 10000)
    period = lookup(each.value, "quota_period", "MONTH")
  }

  throttle_settings {
    burst_limit = lookup(each.value, "throttle_burst_limit", 5000)
    rate_limit  = lookup(each.value, "throttle_rate_limit", 10000)
  }

  tags = var.tags
}

# API Key (REST)
resource "aws_api_gateway_api_key" "this" {
  for_each = var.api_type == "REST" ? var.api_keys : {}

  name        = each.key
  description = lookup(each.value, "description", null)
  enabled     = lookup(each.value, "enabled", true)
  value       = lookup(each.value, "value", null)

  tags = var.tags
}

# Usage Plan Key (REST)
resource "aws_api_gateway_usage_plan_key" "this" {
  for_each = var.api_type == "REST" ? var.usage_plan_keys : {}

  key_id        = aws_api_gateway_api_key.this[each.value.api_key_name].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this[each.value.usage_plan_name].id
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api" {
  count = var.create_log_group ? 1 : 0

  name              = "/aws/apigateway/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = var.tags
}

# WAF Association
resource "aws_wafv2_web_acl_association" "this" {
  count = var.web_acl_arn != null && var.api_type == "REST" ? 1 : 0

  resource_arn = aws_api_gateway_stage.this[0].arn
  web_acl_arn  = var.web_acl_arn
}