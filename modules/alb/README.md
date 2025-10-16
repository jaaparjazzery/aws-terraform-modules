# AWS Application Load Balancer Terraform Module

This module creates an AWS Application Load Balancer with target groups, listeners, and routing rules.

## Features

- HTTP and HTTPS listeners
- Multiple target groups with custom health checks
- Path-based and host-based routing
- SSL/TLS termination
- Multiple SSL certificates support
- Session stickiness
- Access logging to S3
- Cross-zone load balancing
- Static target attachments

## Usage

### Basic Example

```hcl
module "alb" {
  source = "./modules/alb"

  alb_name           = "web-alb"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb.id]
  vpc_id             = module.vpc.vpc_id

  certificate_arn = aws_acm_certificate.main.arn

  target_groups = {
    web = {
      name        = "web-tg"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      
      health_check = {
        enabled             = true
        path                = "/health"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
      
      stickiness = {
        type            = "lb_cookie"
        cookie_duration = 86400
        enabled         = true
      }
    }
  }

  default_target_group_key = "web"

  tags = {
    Environment = "production"
  }
}
```

### Advanced Example with Multiple Target Groups and Routing

```hcl
module "alb" {
  source = "./modules/alb"

  alb_name           = "app-alb"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb.id]
  vpc_id             = module.vpc.vpc_id

  # HTTPS configuration
  enable_https_listener   = true
  enable_http_listener    = true
  http_redirect_to_https  = true
  certificate_arn         = aws_acm_certificate.main.arn
  ssl_policy              = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # Additional SSL certificates for multi-domain
  additional_certificates = {
    domain1 = aws_acm_certificate.domain1.arn
    domain2 = aws_acm_certificate.domain2.arn
  }

  # Access logs
  access_logs_bucket = aws_s3_bucket.alb_logs.id
  access_logs_prefix = "alb-logs/"

  # Target groups
  target_groups = {
    web = {
      name        = "web-tg"
      port        = 3000
      protocol    = "HTTP"
      target_type = "ip"
      deregistration_delay = 30
      
      health_check = {
        enabled             = true
        path                = "/health"
        protocol            = "HTTP"
        matcher             = "200-299"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
      
      stickiness = {
        type            = "lb_cookie"
        cookie_duration = 3600
        enabled         = true
      }
    }
    
    api = {
      name        = "api-tg"
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
      
      health_check = {
        enabled             = true
        path                = "/api/health"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
      
      stickiness = {
        type            = "lb_cookie"
        cookie_duration = 300
        enabled         = false
      }
    }
    
    admin = {
      name        = "admin-tg"
      port        = 9000
      protocol    = "HTTP"
      target_type = "instance"
      
      health_check = {
        enabled             = true
        path                = "/admin/health"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
      
      stickiness = {
        type            = "app_cookie"
        cookie_duration = 7200
        enabled         = true
      }
    }
  }

  default_target_group_key = "web"

  # Listener rules for routing
  listener_rules = {
    api_routing = {
      priority         = 100
      action_type      = "forward"
      target_group_key = "api"
      
      conditions = [
        {
          path_pattern = ["/api/*"]
        }
      ]
    }
    
    admin_routing = {
      priority         = 200
      action_type      = "forward"
      target_group_key = "admin"
      
      conditions = [
        {
          host_header = ["admin.example.com"]
        }
      ]
    }
    
    maintenance = {
      priority    = 300
      action_type = "fixed-response"
      
      fixed_response_config = {
        content_type = "text/plain"
        message_body = "Service temporarily unavailable"
        status_code  = "503"
      }
      
      conditions = [
        {
          path_pattern = ["/maintenance"]
        }
      ]
    }
  }

  # Static target attachments
  target_attachments = {
    web1 = {
      target_group_key = "web"
      target_id        = "10.0.1.100"
      port             = 3000
    }
    web2 = {
      target_group_key = "web"
      target_id        = "10.0.1.101"
      port             = 3000
    }
  }

  tags = {
    Environment = "production"
    Application = "myapp"
  }
}
```

### Internal Load Balancer Example

```hcl
module "internal_alb" {
  source = "./modules/alb"

  alb_name           = "internal-alb"
  internal           = true
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.internal_alb.id]
  vpc_id             = module.vpc.vpc_id

  enable_https_listener  = false
  enable_http_listener   = true
  http_redirect_to_https = false

  target_groups = {
    backend = {
      name        = "backend-tg"
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
      
      health_check = {
        enabled             = true
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
      
      stickiness = {
        type            = "lb_cookie"
        cookie_duration = 86400
        enabled         = false
      }
    }
  }

  default_target_group_key = "backend"

  tags = {
    Environment = "production"
    Type        = "internal"
  }
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| alb_name | Name of the ALB | string | n/a | yes |
| subnet_ids | List of subnet IDs | list(string) | n/a | yes |
| security_group_ids | List of security group IDs | list(string) | n/a | yes |
| vpc_id | VPC ID for target groups | string | n/a | yes |
| internal | Whether the LB is internal | bool | false | no |
| certificate_arn | SSL certificate ARN | string | null | no |
| target_groups | Map of target group configs | map(object) | n/a | yes |
| default_target_group_key | Default target group key | string | null | no |
| listener_rules | Map of listener rules | map(object) | {} | no |
| enable_https_listener | Enable HTTPS listener | bool | true | no |
| http_redirect_to_https | Redirect HTTP to HTTPS | bool | true | no |
| ssl_policy | SSL policy | string | "ELBSecurityPolicy-TLS-1-2-2017-01" | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | DNS name of the ALB |
| alb_zone_id | Zone ID of the ALB |
| target_group_arns | ARNs of target groups |
| https_listener_arn | ARN of HTTPS listener |
