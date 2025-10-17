# AWS CloudFront Distribution Module

Terraform module for creating and managing Amazon CloudFront distributions with advanced features including custom SSL certificates, Lambda@Edge functions, origin groups, geo-restrictions, and WAF integration.

## Features

- **Multiple Origin Types**: S3, ALB, custom origins, and origin groups
- **Custom SSL/TLS**: ACM certificate integration with SNI support
- **Lambda@Edge**: Execute functions at CloudFront edge locations
- **Cache Behaviors**: Multiple cache behaviors with custom settings
- **Origin Access Control**: Secure S3 bucket access
- **Geographic Restrictions**: Whitelist or blacklist countries
- **WAF Integration**: AWS WAF web ACL attachment
- **Custom Error Responses**: Branded error pages
- **Logging**: Access logs to S3
- **HTTP/2 and HTTP/3**: Modern protocol support
- **Origin Failover**: High availability with origin groups
- **Field-Level Encryption**: Sensitive data protection
- **Real-Time Logs**: Kinesis Data Streams integration
- **Response Headers Policies**: Security and CORS headers
- **Cache Policies**: Managed and custom cache policies
- **Origin Request Policies**: Custom headers and query strings

## Usage

### Simple S3 Website Distribution

```hcl
module "s3_cdn" {
  source = "./modules/cloudfront"

  description = "CloudFront distribution for static website"
  
  # S3 Origin
  origins = {
    s3 = {
      domain_name = aws_s3_bucket.website.bucket_regional_domain_name
      origin_id   = "S3-Website"
      
      s3_origin_config = {
        origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
      }
    }
  }
  
  # Default cache behavior
  default_cache_behavior = {
    target_origin_id       = "S3-Website"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    
    compress = true
    
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # Managed-CachingOptimized
    origin_request_policy_id = null
  }
  
  # Custom domain
  aliases = ["www.example.com"]
  
  # SSL certificate
  viewer_certificate = {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  tags = {
    Environment = "production"
  }
}
```

### ALB Origin with Multiple Cache Behaviors

```hcl
module "api_cdn" {
  source = "./modules/cloudfront"

  description = "CloudFront distribution for API"
  price_class = "PriceClass_100"  # North America and Europe only
  
  # ALB Origin
  origins = {
    alb = {
      domain_name = aws_lb.api.dns_name
      origin_id   = "ALB-API"
      
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
      
      custom_headers = {
        "X-Custom-Header" = "CloudFront"
      }
    }
  }
  
  # Default cache behavior - API endpoints
  default_cache_behavior = {
    target_origin_id       = "ALB-API"
    viewer_protocol_policy = "https-only"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"  # Managed-CachingDisabled
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"  # Managed-AllViewer
  }
  
  # Additional cache behaviors
  ordered_cache_behaviors = {
    static = {
      path_pattern           = "/static/*"
      target_origin_id       = "ALB-API"
      viewer_protocol_policy = "https-only"
      
      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      
      compress = true
      
      cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # Managed-CachingOptimized
      
      min_ttl     = 0
      default_ttl = 86400
      max_ttl     = 31536000
    }
  }
  
  # Custom domain
  aliases = ["api.example.com"]
  
  # SSL certificate
  viewer_certificate = {
    acm_certificate_arn      = aws_acm_certificate.api.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  tags = {
    Environment = "production"
    Application = "api"
  }
}
```

### Multi-Origin with Failover

```hcl
module "ha_cdn" {
  source = "./modules/cloudfront"

  description = "High availability CloudFront distribution"
  
  # Primary and failover origins
  origins = {
    primary = {
      domain_name = "primary.example.com"
      origin_id   = "Primary"
      
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
    
    failover = {
      domain_name = "failover.example.com"
      origin_id   = "Failover"
      
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }
  
  # Origin group for automatic failover
  origin_groups = {
    group1 = {
      origin_id = "OriginGroup"
      
      failover_criteria = {
        status_codes = [500, 502, 503, 504]
      }
      
      members = [
        { origin_id = "Primary" },
        { origin_id = "Failover" }
      ]
    }
  }
  
  # Default cache behavior uses origin group
  default_cache_behavior = {
    target_origin_id       = "OriginGroup"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    
    compress = true
    
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }
  
  tags = {
    Environment = "production"
    HA          = "true"
  }
}
```

### Distribution with Lambda@Edge

```hcl
module "edge_cdn" {
  source = "./modules/cloudfront"

  description = "CloudFront with Lambda@Edge functions"
  
  origins = {
    s3 = {
      domain_name = aws_s3_bucket.content.bucket_regional_domain_name
      origin_id   = "S3-Content"
      
      s3_origin_config = {
        origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
      }
    }
  }
  
  default_cache_behavior = {
    target_origin_id       = "S3-Content"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    
    compress = true
    
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    
    # Lambda@Edge functions
    lambda_function_associations = {
      viewer_request = {
        lambda_arn   = aws_lambda_function.auth.qualified_arn
        include_body = false
      }
      
      origin_response = {
        lambda_arn   = aws_lambda_function.headers.qualified_arn
        include_body = false
      }
    }
  }
  
  # Response headers policy
  response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  
  tags = {
    Environment = "production"
  }
}
```

### Advanced Production Distribution

```hcl
module "production_cdn" {
  source = "./modules/cloudfront"

  description = "Production CloudFront distribution"
  enabled     = true
  
  # HTTP/2 and HTTP/3 support
  http_version = "http2and3"
  price_class  = "PriceClass_All"
  
  # Multiple origins
  origins = {
    s3_assets = {
      domain_name = aws_s3_bucket.assets.bucket_regional_domain_name
      origin_id   = "S3-Assets"
      origin_path = "/production"
      
      s3_origin_config = {
        origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
      }
    }
    
    api = {
      domain_name = aws_lb.api.dns_name
      origin_id   = "ALB-API"
      
      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_read_timeout      = 60
        origin_keepalive_timeout = 5
      }
      
      custom_headers = {
        "X-Origin-Verify" = "secret-token-123"
      }
    }
  }
  
  # Default cache behavior
  default_cache_behavior = {
    target_origin_id       = "S3-Assets"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    
    compress = true
    
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }
  
  # Ordered cache behaviors
  ordered_cache_behaviors = {
    api = {
      path_pattern           = "/api/*"
      target_origin_id       = "ALB-API"
      viewer_protocol_policy = "https-only"
      
      allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods  = ["GET", "HEAD"]
      
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"  # CachingDisabled
      origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"  # AllViewer
    }
    
    images = {
      path_pattern           = "/images/*"
      target_origin_id       = "S3-Assets"
      viewer_protocol_policy = "redirect-to-https"
      
      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      
      compress = true
      
      cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      
      min_ttl     = 0
      default_ttl = 86400
      max_ttl     = 31536000
    }
  }
  
  # Custom error responses
  custom_error_responses = {
    404 = {
      error_code         = 404
      response_code      = 404
      response_page_path = "/errors/404.html"
      error_caching_min_ttl = 300
    }
    
    500 = {
      error_code         = 500
      response_code      = 500
      response_page_path = "/errors/500.html"
      error_caching_min_ttl = 60
    }
  }
  
  # Geographic restrictions
  geo_restriction = {
    restriction_type = "whitelist"
    locations        = ["US", "CA", "GB", "DE"]
  }
  
  # Custom domain names
  aliases = ["cdn.example.com", "assets.example.com"]
  
  # SSL/TLS configuration
  viewer_certificate = {
    acm_certificate_arn      = aws_acm_certificate.cdn.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  # WAF integration
  web_acl_id = aws_wafv2_web_acl.cdn.arn
  
  # Access logging
  logging_config = {
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/"
    include_cookies = false
  }
  
  # Real-time logs
  realtime_log_config_arn = aws_cloudfront_realtime_log_config.main.arn
  
  # Default root object
  default_root_object = "index.html"
  
  tags = {
    Environment = "production"
    Application = "web-app"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| description | Description of the CloudFront distribution | `string` | n/a | yes |
| enabled | Whether the distribution is enabled | `bool` | `true` | no |
| origins | Map of origin configurations | `map(any)` | n/a | yes |
| origin_groups | Map of origin group configurations | `map(any)` | `{}` | no |
| default_cache_behavior | Default cache behavior configuration | `any` | n/a | yes |
| ordered_cache_behaviors | Map of ordered cache behaviors | `map(any)` | `{}` | no |
| aliases | Alternate domain names (CNAMEs) | `list(string)` | `[]` | no |
| viewer_certificate | SSL certificate configuration | `any` | `null` | no |
| price_class | Price class for distribution | `string` | `"PriceClass_All"` | no |
| http_version | Maximum HTTP version (http1.1, http2, http2and3) | `string` | `"http2and3"` | no |
| web_acl_id | AWS WAF web ACL ARN | `string` | `null` | no |
| logging_config | Access logging configuration | `object` | `null` | no |
| realtime_log_config_arn | Real-time log configuration ARN | `string` | `null` | no |
| default_root_object | Object to return for root URL | `string` | `"index.html"` | no |
| custom_error_responses | Map of custom error response configurations | `map(any)` | `{}` | no |
| geo_restriction | Geographic restriction configuration | `object` | `null` | no |
| is_ipv6_enabled | Enable IPv6 | `bool` | `true` | no |
| comment | Comment for the distribution | `string` | `""` | no |
| retain_on_delete | Disable distribution before deletion | `bool` | `false` | no |
| wait_for_deployment | Wait for distribution deployment | `bool` | `true` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| distribution_id | ID of the CloudFront distribution |
| distribution_arn | ARN of the CloudFront distribution |
| distribution_domain_name | Domain name of the distribution |
| distribution_hosted_zone_id | Route 53 zone ID for the distribution |
| distribution_status | Current status of the distribution |
| etag | Current version of the distribution |

## Examples

### SPA with Custom Error Pages

```hcl
module "spa_cdn" {
  source = "./modules/cloudfront"

  description = "Single Page Application CDN"
  
  origins = {
    s3 = {
      domain_name = aws_s3_bucket.spa.bucket_regional_domain_name
      origin_id   = "S3-SPA"
      
      s3_origin_config = {
        origin_access_control_id = aws_cloudfront_origin_access_control.spa.id
      }
    }
  }
  
  default_cache_behavior = {
    target_origin_id       = "S3-SPA"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    
    compress = true
    
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }
  
  # SPA routing - return index.html for 404s
  custom_error_responses = {
    404 = {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
      error_caching_min_ttl = 0
    }
  }
  
  aliases = ["app.example.com"]
  
  viewer_certificate = {
    acm_certificate_arn      = aws_acm_certificate.app.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  tags = {
    Environment = "production"
    AppType     = "spa"
  }
}
```

## Best Practices

### Performance

- Use **HTTP/2 and HTTP/3** for better performance
- Enable **compression** for text-based content
- Use **cache policies** instead of legacy cache settings
- Configure **origin keep-alive** for persistent connections
- Use **Origin Shield** for high cache hit ratios
- Implement **cache key normalization** for better cache efficiency

### Security

- Always use **HTTPS** (redirect-to-https or https-only)
- Use **TLSv1.2 or higher** as minimum protocol version
- Implement **AWS WAF** for application protection
- Use **Origin Access Control** for S3 buckets
- Add **security headers** via response headers policies
- Use **signed URLs or cookies** for restricted content
- Enable **field-level encryption** for sensitive data

### Cost Optimization

- Choose appropriate **price class** based on audience
- Use **cache policies** to maximize cache hit ratio
- Enable **compression** to reduce data transfer
- Use **S3 Transfer Acceleration** only when needed
- Consider **reserved capacity** for predictable traffic
- Monitor and optimize **origin requests**

### High Availability

- Use **origin groups** with failover
- Configure **custom error responses**
- Set appropriate **origin timeouts**
- Use **health checks** with origin groups
- Implement **retry logic** in Lambda@Edge

### Monitoring

- Enable **access logging** to S3
- Use **CloudWatch metrics** for monitoring
- Set up **alarms** for error rates
- Monitor **cache hit ratio**
- Use **real-time logs** for debugging

## Cost Considerations

### Pricing Components

**Data Transfer Out:**
- First 10 TB: $0.085 per GB (varies by region)
- Next 40 TB: $0.080 per GB
- Over 150 TB: $0.060 per GB

**HTTP/HTTPS Requests:**
- HTTP: $0.0075 per 10,000 requests
- HTTPS: $0.0100 per 10,000 requests

**Additional Features:**
- Origin Shield: $0.010 per 10,000 requests
- Field-level encryption: $0.020 per 10,000 requests
- Real-time logs: $0.010 per 1,000,000 log lines
- Lambda@Edge: Separate Lambda charges apply

**Dedicated IP (Legacy):**
- $600 per month (use SNI instead)

### Example Costs

| Traffic Profile | Data Transfer | Requests | Monthly Cost |
|-----------------|---------------|----------|--------------|
| Small website | 100 GB | 1M | ~$10 |
| Medium app | 1 TB | 100M | ~$120 |
| Large platform | 10 TB | 1B | ~$980 |
| Enterprise | 100 TB | 10B | ~$7,600 |

**Note**: Prices are approximate for us-east-1 region. Actual costs vary by region and edge location.

## Additional Resources

- [CloudFront Developer Guide](https://docs.aws.amazon.com/cloudfront/latest/developerguide/)
- [CloudFront Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/best-practices.html)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [Lambda@Edge Guide](https://docs.aws.amazon.com/lambda/latest/dg/lambda-edge.html)

## License

This module is licensed under the MIT License.