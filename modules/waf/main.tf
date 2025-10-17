# modules/cloudfront/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = var.comment
  default_root_object = var.default_root_object
  aliases             = var.aliases
  price_class         = var.price_class
  http_version        = var.http_version
  web_acl_id          = var.web_acl_id
  retain_on_delete    = var.retain_on_delete
  wait_for_deployment = var.wait_for_deployment

  dynamic "origin" {
    for_each = var.origins
    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id
      origin_path              = lookup(origin.value, "origin_path", "")
      connection_attempts      = lookup(origin.value, "connection_attempts", 3)
      connection_timeout       = lookup(origin.value, "connection_timeout", 10)
      origin_access_control_id = lookup(origin.value, "origin_access_control_id", null)

      dynamic "custom_origin_config" {
        for_each = lookup(origin.value, "custom_origin_config", null) != null ? [origin.value.custom_origin_config] : []
        content {
          http_port                = lookup(custom_origin_config.value, "http_port", 80)
          https_port               = lookup(custom_origin_config.value, "https_port", 443)
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = lookup(custom_origin_config.value, "origin_ssl_protocols", ["TLSv1.2"])
          origin_keepalive_timeout = lookup(custom_origin_config.value, "origin_keepalive_timeout", 5)
          origin_read_timeout      = lookup(custom_origin_config.value, "origin_read_timeout", 30)
        }
      }

      dynamic "s3_origin_config" {
        for_each = lookup(origin.value, "s3_origin_config", null) != null ? [origin.value.s3_origin_config] : []
        content {
          origin_access_identity = lookup(s3_origin_config.value, "origin_access_identity", null)
        }
      }

      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_headers", [])
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "origin_shield" {
        for_each = lookup(origin.value, "origin_shield", null) != null ? [origin.value.origin_shield] : []
        content {
          enabled              = origin_shield.value.enabled
          origin_shield_region = origin_shield.value.origin_shield_region
        }
      }
    }
  }

  dynamic "origin_group" {
    for_each = var.origin_groups
    content {
      origin_id = origin_group.value.origin_id

      failover_criteria {
        status_codes = origin_group.value.failover_status_codes
      }

      member {
        origin_id = origin_group.value.primary_member_origin_id
      }

      member {
        origin_id = origin_group.value.secondary_member_origin_id
      }
    }
  }

  default_cache_behavior {
    allowed_methods        = var.default_cache_behavior.allowed_methods
    cached_methods         = var.default_cache_behavior.cached_methods
    target_origin_id       = var.default_cache_behavior.target_origin_id
    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy
    compress               = lookup(var.default_cache_behavior, "compress", true)
    cache_policy_id        = lookup(var.default_cache_behavior, "cache_policy_id", null)
    origin_request_policy_id = lookup(var.default_cache_behavior, "origin_request_policy_id", null)
    response_headers_policy_id = lookup(var.default_cache_behavior, "response_headers_policy_id", null)
    realtime_log_config_arn = lookup(var.default_cache_behavior, "realtime_log_config_arn", null)
    field_level_encryption_id = lookup(var.default_cache_behavior, "field_level_encryption_id", null)
    smooth_streaming = lookup(var.default_cache_behavior, "smooth_streaming", false)
    trusted_key_groups = lookup(var.default_cache_behavior, "trusted_key_groups", [])
    trusted_signers = lookup(var.default_cache_behavior, "trusted_signers", [])

    dynamic "forwarded_values" {
      for_each = lookup(var.default_cache_behavior, "forwarded_values", null) != null ? [var.default_cache_behavior.forwarded_values] : []
      content {
        query_string = forwarded_values.value.query_string
        headers      = lookup(forwarded_values.value, "headers", [])

        cookies {
          forward           = forwarded_values.value.cookies_forward
          whitelisted_names = lookup(forwarded_values.value, "cookies_whitelisted_names", [])
        }
      }
    }

    dynamic "function_association" {
      for_each = lookup(var.default_cache_behavior, "function_associations", [])
      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }

    dynamic "lambda_function_association" {
      for_each = lookup(var.default_cache_behavior, "lambda_function_associations", [])
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lookup(lambda_function_association.value, "include_body", false)
      }
    }

    min_ttl     = lookup(var.default_cache_behavior, "min_ttl", null)
    default_ttl = lookup(var.default_cache_behavior, "default_ttl", null)
    max_ttl     = lookup(var.default_cache_behavior, "max_ttl", null)
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      compress               = lookup(ordered_cache_behavior.value, "compress", true)
      cache_policy_id        = lookup(ordered_cache_behavior.value, "cache_policy_id", null)
      origin_request_policy_id = lookup(ordered_cache_behavior.value, "origin_request_policy_id", null)
      response_headers_policy_id = lookup(ordered_cache_behavior.value, "response_headers_policy_id", null)
      realtime_log_config_arn = lookup(ordered_cache_behavior.value, "realtime_log_config_arn", null)
      field_level_encryption_id = lookup(ordered_cache_behavior.value, "field_level_encryption_id", null)
      smooth_streaming = lookup(ordered_cache_behavior.value, "smooth_streaming", false)
      trusted_key_groups = lookup(ordered_cache_behavior.value, "trusted_key_groups", [])
      trusted_signers = lookup(ordered_cache_behavior.value, "trusted_signers", [])

      dynamic "forwarded_values" {
        for_each = lookup(ordered_cache_behavior.value, "forwarded_values", null) != null ? [ordered_cache_behavior.value.forwarded_values] : []
        content {
          query_string = forwarded_values.value.query_string
          headers      = lookup(forwarded_values.value, "headers", [])

          cookies {
            forward           = forwarded_values.value.cookies_forward
            whitelisted_names = lookup(forwarded_values.value, "cookies_whitelisted_names", [])
          }
        }
      }

      dynamic "function_association" {
        for_each = lookup(ordered_cache_behavior.value, "function_associations", [])
        content {
          event_type   = function_association.value.event_type
          function_arn = function_association.value.function_arn
        }
      }

      dynamic "lambda_function_association" {
        for_each = lookup(ordered_cache_behavior.value, "lambda_function_associations", [])
        content {
          event_type   = lambda_function_association.value.event_type
          lambda_arn   = lambda_function_association.value.lambda_arn
          include_body = lookup(lambda_function_association.value, "include_body", false)
        }
      }

      min_ttl     = lookup(ordered_cache_behavior.value, "min_ttl", null)
      default_ttl = lookup(ordered_cache_behavior.value, "default_ttl", null)
      max_ttl     = lookup(ordered_cache_behavior.value, "max_ttl", null)
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn != null ? var.ssl_support_method : null
    minimum_protocol_version       = var.minimum_protocol_version
    cloudfront_default_certificate = var.acm_certificate_arn == null
  }

  dynamic "logging_config" {
    for_each = var.logging_enabled ? [1] : []
    content {
      bucket          = var.logging_bucket
      prefix          = var.logging_prefix
      include_cookies = var.logging_include_cookies
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
    }
  }

  tags = var.tags
}

# Origin Access Control (OAC) for S3
resource "aws_cloudfront_origin_access_control" "this" {
  for_each = var.origin_access_controls

  name                              = each.key
  description                       = lookup(each.value, "description", "")
  origin_access_control_origin_type = lookup(each.value, "origin_type", "s3")
  signing_behavior                  = lookup(each.value, "signing_behavior", "always")
  signing_protocol                  = lookup(each.value, "signing_protocol", "sigv4")
}

# CloudFront Function
resource "aws_cloudfront_function" "this" {
  for_each = var.cloudfront_functions

  name    = each.key
  runtime = lookup(each.value, "runtime", "cloudfront-js-1.0")
  comment = lookup(each.value, "comment", "")
  code    = each.value.code
  publish = lookup(each.value, "publish", true)
}