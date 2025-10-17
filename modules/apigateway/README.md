# AWS API Gateway Module

Terraform module for creating and managing AWS API Gateway (REST API, HTTP API, and WebSocket API) with advanced features including Lambda integrations, custom domains, request/response transformations, and comprehensive monitoring.

## Features

- **Multiple API Types**: REST API, HTTP API (v2), and WebSocket API
- **Lambda Integration**: Direct Lambda function integration with proxy and non-proxy modes
- **Custom Domains**: Custom domain names with SSL certificates
- **Authorization**: API Keys, Lambda authorizers, Cognito, IAM, and JWT
- **Request Validation**: Request and response model validation
- **Throttling**: Stage-level and method-level throttling
- **Caching**: Response caching for improved performance
- **CORS**: Built-in CORS configuration
- **VPC Links**: Private integration with VPC resources
- **Usage Plans**: API keys and usage quotas
- **Canary Deployments**: Staged deployments with traffic shifting
- **Request/Response Transformation**: VTL templates for data mapping
- **CloudWatch Integration**: Detailed logging and metrics
- **WAF Integration**: AWS WAF web ACL protection
- **X-Ray Tracing**: Distributed tracing support

## Usage

### Simple REST API with Lambda Integration

```hcl
module "simple_api" {
  source = "./modules/api-gateway"

  api_name    = "simple-api"
  description = "Simple REST API"
  api_type    = "REST"
  
  # Lambda integration
  integrations = {
    "GET /users" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.get_users_lambda.function_invoke_arn
    }
    
    "POST /users" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.create_user_lambda.function_invoke_arn
    }
  }
  
  # Lambda permissions
  lambda_permissions = {
    get_users = {
      function_name = module.get_users_lambda.function_name
      source_arn    = "${module.simple_api.execution_arn}/*/*/*"
    }
    
    create_user = {
      function_name = module.create_user_lambda.function_name
      source_arn    = "${module.simple_api.execution_arn}/*/*/*"
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### HTTP API (v2) with JWT Authorization

```hcl
module "http_api" {
  source = "./modules/api-gateway"

  api_name    = "modern-api"
  description = "Modern HTTP API with JWT auth"
  api_type    = "HTTP"
  
  # CORS configuration
  cors_configuration = {
    allow_origins = ["https://example.com"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["Authorization", "Content-Type"]
    max_age       = 3600
  }
  
  # JWT Authorizer
  authorizers = {
    jwt = {
      type          = "JWT"
      identity_sources = ["$request.header.Authorization"]
      
      jwt_configuration = {
        audience = ["api.example.com"]
        issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_ABC123"
      }
    }
  }
  
  # Routes with authorization
  integrations = {
    "GET /protected" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.protected_lambda.function_invoke_arn
      authorizer_key         = "jwt"
    }
    
    "GET /public" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.public_lambda.function_invoke_arn
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### REST API with Request Validation and Models

```hcl
module "validated_api" {
  source = "./modules/api-gateway"

  api_name    = "validated-api"
  description = "API with request validation"
  api_type    = "REST"
  
  # Request/Response models
  models = {
    UserRequest = {
      content_type = "application/json"
      schema = jsonencode({
        type = "object"
        required = ["email", "name"]
        properties = {
          email = {
            type = "string"
            format = "email"
          }
          name = {
            type = "string"
            minLength = 1
          }
          age = {
            type = "integer"
            minimum = 0
          }
        }
      })
    }
    
    UserResponse = {
      content_type = "application/json"
      schema = jsonencode({
        type = "object"
        properties = {
          id = { type = "string" }
          email = { type = "string" }
          name = { type = "string" }
          created_at = { type = "string" }
        }
      })
    }
  }
  
  # Request validators
  request_validators = {
    body_validator = {
      validate_request_body       = true
      validate_request_parameters = false
    }
    
    params_validator = {
      validate_request_body       = false
      validate_request_parameters = true
    }
  }
  
  # Routes with validation
  integrations = {
    "POST /users" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.create_user_lambda.function_invoke_arn
      request_validator_key  = "body_validator"
      request_model_key      = "UserRequest"
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### API with Custom Domain and Usage Plans

```hcl
module "enterprise_api" {
  source = "./modules/api-gateway"

  api_name    = "enterprise-api"
  description = "Enterprise API with usage plans"
  api_type    = "REST"
  
  # Integrations
  integrations = {
    "GET /data" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.data_lambda.function_invoke_arn
    }
  }
  
  # Custom domain
  custom_domain = {
    domain_name              = "api.example.com"
    certificate_arn          = aws_acm_certificate.api.arn
    security_policy          = "TLS_1_2"
    endpoint_type            = "REGIONAL"
  }
  
  # API Keys and Usage Plans
  api_keys = {
    partner_key = {
      name        = "Partner API Key"
      description = "API key for partner integration"
    }
    
    internal_key = {
      name        = "Internal API Key"
      description = "API key for internal services"
    }
  }
  
  usage_plans = {
    basic = {
      name        = "Basic Plan"
      description = "Basic usage plan"
      
      api_stages = [{
        api_id = module.enterprise_api.api_id
        stage  = "prod"
      }]
      
      quota_settings = {
        limit  = 10000
        period = "MONTH"
      }
      
      throttle_settings = {
        rate_limit  = 100
        burst_limit = 200
      }
      
      api_keys = ["partner_key"]
    }
    
    premium = {
      name        = "Premium Plan"
      description = "Premium usage plan"
      
      api_stages = [{
        api_id = module.enterprise_api.api_id
        stage  = "prod"
      }]
      
      quota_settings = {
        limit  = 1000000
        period = "MONTH"
      }
      
      throttle_settings = {
        rate_limit  = 1000
        burst_limit = 2000
      }
      
      api_keys = ["internal_key"]
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### WebSocket API for Real-Time Communication

```hcl
module "websocket_api" {
  source = "./modules/api-gateway"

  api_name    = "chat-websocket"
  description = "WebSocket API for chat application"
  api_type    = "WEBSOCKET"
  
  # Route selection expression
  route_selection_expression = "$request.body.action"
  
  # WebSocket routes
  integrations = {
    "$connect" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.connect_lambda.function_invoke_arn
    }
    
    "$disconnect" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.disconnect_lambda.function_invoke_arn
    }
    
    "sendMessage" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.send_message_lambda.function_invoke_arn
    }
    
    "$default" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.default_lambda.function_invoke_arn
    }
  }
  
  tags = {
    Environment = "production"
    Protocol    = "websocket"
  }
}
```

### Advanced Production API

```hcl
module "production_api" {
  source = "./modules/api-gateway"

  api_name    = "production-api"
  description = "Production-grade REST API"
  api_type    = "REST"
  
  # API configuration
  endpoint_type = "REGIONAL"
  
  # Stage configuration
  stage_name = "prod"
  
  stage_settings = {
    logging_level          = "INFO"
    data_trace_enabled     = true
    metrics_enabled        = true
    throttling_rate_limit  = 1000
    throttling_burst_limit = 2000
    caching_enabled        = true
    cache_ttl_in_seconds   = 300
    cache_cluster_size     = "0.5"
  }
  
  # Lambda Authorizer
  authorizers = {
    token = {
      type                   = "TOKEN"
      authorizer_uri         = module.authorizer_lambda.function_invoke_arn
      identity_source        = "method.request.header.Authorization"
      authorizer_result_ttl  = 300
    }
  }
  
  # Request models and validators
  models = {
    ErrorResponse = {
      content_type = "application/json"
      schema = jsonencode({
        type = "object"
        properties = {
          error = { type = "string" }
          message = { type = "string" }
        }
      })
    }
  }
  
  request_validators = {
    all = {
      validate_request_body       = true
      validate_request_parameters = true
    }
  }
  
  # API resources and methods
  integrations = {
    "GET /api/v1/users" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.list_users_lambda.function_invoke_arn
      authorizer_key         = "token"
      api_key_required       = true
    }
    
    "GET /api/v1/users/{id}" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.get_user_lambda.function_invoke_arn
      authorizer_key         = "token"
      
      request_parameters = {
        "method.request.path.id" = true
      }
    }
    
    "POST /api/v1/users" = {
      type                   = "AWS_PROXY"
      integration_http_method = "POST"
      uri                    = module.create_user_lambda.function_invoke_arn
      authorizer_key         = "token"
      api_key_required       = true
      request_validator_key  = "all"
    }
  }
  
  # Custom domain
  custom_domain = {
    domain_name     = "api.example.com"
    certificate_arn = aws_acm_certificate.api.arn
    security_policy = "TLS_1_2"
    base_path       = "v1"
  }
  
  # WAF integration
  web_acl_arn = aws_wafv2_web_acl.api.arn
  
  # X-Ray tracing
  xray_tracing_enabled = true
  
  # Access logging
  access_log_settings = {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
  
  # Canary deployment
  canary_settings = {
    percent_traffic         = 10
    use_stage_cache         = false
    stage_variable_overrides = {
      lambda_alias = "canary"
    }
  }
  
  tags = {
    Environment  = "production"
    Compliance   = "pci-dss"
    CriticalPath = "true"
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
| api_name | Name of the API Gateway | `string` | n/a | yes |
| description | Description of the API | `string` | `""` | no |
| api_type | Type of API (REST, HTTP, or WEBSOCKET) | `string` | `"REST"` | no |
| endpoint_type | Endpoint type (REGIONAL, EDGE, PRIVATE) | `string` | `"REGIONAL"` | no |
| integrations | Map of route/method to integration configurations | `map(any)` | n/a | yes |
| authorizers | Map of authorizer configurations | `map(any)` | `{}` | no |
| models | Map of request/response models | `map(any)` | `{}` | no |
| request_validators | Map of request validator configurations | `map(any)` | `{}` | no |
| stage_name | Stage name for deployment | `string` | `"prod"` | no |
| stage_settings | Stage-level settings | `object` | `{}` | no |
| custom_domain | Custom domain configuration | `object` | `null` | no |
| api_keys | Map of API key configurations | `map(any)` | `{}` | no |
| usage_plans | Map of usage plan configurations | `map(any)` | `{}` | no |
| cors_configuration | CORS configuration (HTTP API only) | `object` | `null` | no |
| route_selection_expression | Route selection expression (WebSocket only) | `string` | `null` | no |
| web_acl_arn | AWS WAF web ACL ARN | `string` | `null` | no |
| xray_tracing_enabled | Enable X-Ray tracing | `bool` | `false` | no |
| access_log_settings | Access log configuration | `object` | `null` | no |
| canary_settings | Canary deployment settings | `object` | `null` | no |
| lambda_permissions | Lambda permissions to create | `map(any)` | `{}` | no |
| vpc_link_ids | VPC Link IDs for private integrations | `list(string)` | `[]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_id | ID of the API Gateway |
| api_arn | ARN of the API Gateway |
| api_endpoint | Base URL of the API |
| execution_arn | Execution ARN for Lambda permissions |
| stage_arn | ARN of the deployment stage |
| stage_invoke_url | Invoke URL for the stage |
| custom_domain_name | Custom domain name (if configured) |
| api_key_values | API key values (marked as sensitive) |

## Examples

### Microservices API

```hcl
module "microservices_api" {
  source = "./modules/api-gateway"

  api_name    = "microservices-api"
  description = "API Gateway for microservices"
  api_type    = "REST"
  
  # Multiple service integrations
  integrations = {
    "GET /users/{proxy+}" = {
      type                   = "HTTP_PROXY"
      integration_http_method = "ANY"
      uri                    = "http://${aws_lb.user_service.dns_name}/{proxy}"
      connection_type        = "VPC_LINK"
      connection_id          = aws_api_gateway_vpc_link.main.id
      request_parameters = {
        "integration.request.path.proxy" = "method.request.path.proxy"
      }
    }
    
    "GET /orders/{proxy+}" = {
      type                   = "HTTP_PROXY"
      integration_http_method = "ANY"
      uri                    = "http://${aws_lb.order_service.dns_name}/{proxy}"
      connection_type        = "VPC_LINK"
      connection_id          = aws_api_gateway_vpc_link.main.id
      request_parameters = {
        "integration.request.path.proxy" = "method.request.path.proxy"
      }
    }
  }
  
  tags = {
    Architecture = "microservices"
  }
}
```

## Best Practices

### Performance

- Use **HTTP API** for lower latency and cost
- Enable **caching** for frequently accessed resources
- Use **Lambda proxy integration** for simplicity
- Configure appropriate **timeout values**
- Use **VPC Links** for private integrations
- Enable **compression** for large responses

### Security

- Always use **HTTPS** endpoints
- Implement **API keys** and **usage plans**
- Use **Lambda authorizers** or **Cognito** for authentication
- Enable **AWS WAF** for DDoS and bot protection
- Use **resource policies** for additional access control
- Enable **X-Ray tracing** for security insights
- Validate **request/response models**
- Use **mutual TLS** for client certificate authentication

### Cost Optimization

- Choose **HTTP API** over REST API when possible (60% cheaper)
- Use **caching** to reduce backend requests
- Implement **throttling** to prevent abuse
- Use **usage plans** with quotas
- Monitor and optimize **data transfer**
- Consider **WebSocket API** for real-time bidirectional communication

### Reliability

- Implement **canary deployments** for gradual rollouts
- Set up **CloudWatch alarms** for errors
- Use **stage variables** for environment configuration
- Configure **retry logic** in Lambda functions
- Implement **circuit breakers** for backend failures
- Use **API Gateway throttling** to protect backends

### Monitoring

- Enable **CloudWatch Logs** and metrics
- Configure **access logging** to S3 or CloudWatch
- Use **X-Ray tracing** for distributed tracing
- Monitor **4xx and 5xx errors**
- Track **integration latency**
- Set up **alarms** for throttling

## Cost Considerations

### REST API Pricing

- First 333M requests: $3.50 per million
- Next 667M requests: $2.80 per million
- Over 1B requests: $2.38 per million
- Caching: $0.02 per hour per GB

### HTTP API Pricing (60% cheaper)

- First 300M requests: $1.00 per million
- Over 300M requests: $0.90 per million

### WebSocket API Pricing

- Connection minutes: $0.25 per million
- Messages: $1.00 per million

### Example Costs

| API Type | Monthly Requests | Caching | Monthly Cost |
|----------|------------------|---------|--------------|
| REST API | 1M | No | ~$3.50 |
| REST API | 100M | Yes | ~$337 |
| HTTP API | 100M | N/A | ~$100 |
| WebSocket | 10M messages | N/A | ~$10 |

**Note**: Prices are approximate. Additional costs for data transfer and Lambda invocations apply.

## Additional Resources

- [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/)
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/best-practices.html)
- [API Gateway Pricing](https://aws.amazon.com/api-gateway/pricing/)
- [Building APIs with Lambda](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html)

## License

This module is licensed under the MIT License.