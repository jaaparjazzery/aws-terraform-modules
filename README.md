- [DevOps Subreddit](https://www.reddit.com/r/devops/)
- [Infrastructure as Code Slack](https://invite.slack.golevelup.com/)

**[Back to Resources](#additional-resources)** | **[Back to Top](#quick-navigation)**

---

## Roadmap

**Navigation:** [Back to Top](#quick-navigation) | [Current Focus](#current-focus) | [Future Plans](#future-enhancements)# AWS Terraform Modules Collection

A comprehensive collection of production-ready Terraform modules for AWS infrastructure. These modules follow AWS and HashiCorp best practices, with security-first defaults and extensive customization options.

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Provider%20%3E%3D5.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Quick Navigation

**[Jump to Module Documentation](#module-documentation)** | **[View Complete Examples](#complete-infrastructure-examples)** | **[Best Practices](#best-practices)** | **[Cost Guide](#cost-considerations)**

### Module Quick Links

**Compute & Serverless**
- [Lambda Function](#lambda-function-module) | [EC2 Instance](#ec2-instance-module) | [EKS Cluster](#eks-cluster-module)

**Storage & Database**
- [S3 Bucket](#s3-bucket-module) | [DynamoDB](#dynamodb-table-module) | [RDS Database](#rds-database-module) | [ElastiCache](#elasticache-module) | [ECR](#ecr-repository-module)

**Networking & CDN**
- [VPC](#vpc-module) | [Load Balancer](#application-load-balancer-module) | [CloudFront](#cloudfront-distribution-module) | [Route53](#route53-module)

**Integration & Messaging**
- [API Gateway](#api-gateway-module) | [Step Functions](#step-functions-module) | [SNS/SQS](#snssqs-module)

**Security**
- [WAF](#waf-module)

---

## Table of Contents

- [Overview](#overview)
- [Available Modules](#available-modules)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Module Documentation](#module-documentation)
- [Complete Infrastructure Examples](#complete-infrastructure-examples)
- [Best Practices](#best-practices)
- [Testing](#testing)
- [Cost Considerations](#cost-considerations)
- [Contributing](#contributing)
- [Support](#support)

## Overview

This repository contains reusable Terraform modules for common AWS services. Each module is designed to be:

- **Production-ready**: Includes security best practices and monitoring
- **Flexible**: Highly configurable with sensible defaults
- **Secure**: Encryption enabled by default where applicable
- **Observable**: CloudWatch logging and alarms built-in
- **Well-documented**: Comprehensive examples and documentation

## Available Modules

### Compute & Serverless

| Module | Description | Status |
|--------|-------------|--------|
| [Lambda](#lambda-function-module) | AWS Lambda functions with IAM, logging, and event triggers | ✅ Ready |
| [EC2 Instance](#ec2-instance-module) | Flexible EC2 instances with automatic AMI lookup | ✅ Ready |
| [EKS Cluster](#eks-cluster-module) | Production-ready Amazon EKS clusters with managed node groups | ✅ Ready |

### Storage & Database

| Module | Description | Status |
|--------|-------------|--------|
| [S3 Bucket](#s3-bucket-module) | Secure S3 buckets with encryption and versioning | ✅ Ready |
| [DynamoDB](#dynamodb-table-module) | DynamoDB tables with autoscaling and alarms | ✅ Ready |
| [RDS Database](#rds-database-module) | Managed database instances with high availability | ✅ Ready |
| [ElastiCache](#elasticache-module) | Redis and Memcached clusters | ✅ Ready |
| [ECR](#ecr-repository-module) | Elastic Container Registry with lifecycle policies | ✅ Ready |

### Networking & Content Delivery

| Module | Description | Status |
|--------|-------------|--------|
| [VPC](#vpc-module) | Complete networking infrastructure with subnets and NAT | ✅ Ready |
| [Application Load Balancer](#application-load-balancer-module) | ALB with advanced routing and SSL/TLS termination | ✅ Ready |
| [CloudFront](#cloudfront-distribution-module) | CloudFront distributions with OAC and functions | ✅ Ready |
| [Route53](#route53-module) | DNS zones, records, and health checks | ✅ Ready |

### Application Integration

| Module | Description | Status |
|--------|-------------|--------|
| [API Gateway](#api-gateway-module) | REST, HTTP, and WebSocket APIs | ✅ Ready |
| [Step Functions](#step-functions-module) | State machines with EventBridge integration | ✅ Ready |
| [SNS/SQS](#snssqs-module) | Messaging with SNS topics and SQS queues | ✅ Ready |

### Security

| Module | Description | Status |
|--------|-------------|--------|
| [WAF](#waf-module) | Web Application Firewall rules and IP sets | ✅ Ready |

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS Account with necessary permissions
- Basic understanding of Terraform and AWS services

## Quick Start

### Installation

Clone this repository:

```bash
git clone https://github.com/jaaparjazzery/aws-terraform-modules.git
cd aws-terraform-modules
```

### Basic Usage Example

Here's a simple example that creates a Lambda function:

```hcl
# Configure AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create Lambda Function
module "lambda" {
  source = "./modules/lambda"

  function_name = "my-function"
  runtime       = "python3.11"
  handler       = "index.handler"
  filename      = "lambda.zip"

  environment_variables = {
    ENV = "production"
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Module Documentation

**Navigation:** [Back to Top](#quick-navigation) | [View All Modules](#module-quick-links)

---

### VPC Module
**[Quick Jump](#module-quick-links)** | **[Next: S3 Bucket](#s3-bucket-module)**

Complete networking infrastructure with public/private subnets, NAT gateways, and route tables.

**Features:**
- Multi-AZ subnet configuration
- NAT Gateway for private subnet internet access
- Internet Gateway for public subnets
- Customizable CIDR blocks
- DNS support enabled by default
- VPC Flow Logs support

**Example:**

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "production-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  
  enable_nat_gateway = true
  
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

**Outputs:**
- `vpc_id` - VPC ID
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### S3 Bucket Module
**[Quick Jump](#module-quick-links)** | **[Previous: VPC](#vpc-module)** | **[Next: EC2 Instance](#ec2-instance-module)**

Secure S3 buckets with encryption, versioning, and lifecycle management.

**Features:**
- Server-side encryption (AES256 or KMS)
- Versioning support
- Public access blocking by default
- Lifecycle rules for storage tiering
- Access logging and CORS configuration
- Replication support

**Example:**

```hcl
module "app_bucket" {
  source = "./modules/s3-bucket"

  bucket_name        = "my-app-assets-${random_id.bucket_suffix.hex}"
  versioning_enabled = true
  
  lifecycle_rules = [
    {
      id      = "archive-old-objects"
      enabled = true
      
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      
      expiration_days = 365
    }
  ]
  
  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `bucket_id` - S3 bucket ID
- `bucket_arn` - Bucket ARN
- `bucket_regional_domain_name` - Regional domain name

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### EC2 Instance Module
**[Quick Jump](#module-quick-links)** | **[Previous: S3 Bucket](#s3-bucket-module)** | **[Next: RDS Database](#rds-database-module)**

Flexible EC2 instances with automatic AMI lookup and advanced configuration options.

**Features:**
- Automatic latest AMI selection
- Multiple EBS volumes support
- IMDSv2 enforcement for security
- Elastic IP support
- User data and IAM instance profiles
- Detailed monitoring options

**Example:**

```hcl
module "web_server" {
  source = "./modules/ec2-instance"

  instance_name      = "web-server-01"
  instance_type      = "t3.medium"
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [aws_security_group.web.id]
  key_name           = "my-key-pair"
  
  associate_public_ip = true
  
  root_volume_size = 30
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF
  
  tags = {
    Environment = "production"
    Role        = "web"
  }
}
```

**Outputs:**
- `instance_id` - EC2 instance ID
- `public_ip` - Public IP address
- `private_ip` - Private IP address

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### RDS Database Module
**[Quick Jump](#module-quick-links)** | **[Previous: EC2 Instance](#ec2-instance-module)** | **[Next: Application Load Balancer](#application-load-balancer-module)**

Managed database instances with high availability and backup configurations.

**Features:**
- Support for PostgreSQL, MySQL, MariaDB, and more
- Multi-AZ deployments
- Read replica support
- Automated backups with configurable retention
- Performance Insights
- Enhanced monitoring
- Encryption at rest

**Example:**

```hcl
module "rds" {
  source = "./modules/rds"

  db_identifier   = "production-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.large"

  database_name   = "myapp"
  master_username = "admin"
  master_password = var.db_password

  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.database.id]

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds.arn

  multi_az                = true
  backup_retention_period = 14
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `db_instance_endpoint` - Database endpoint
- `db_instance_arn` - Database ARN
- `db_instance_id` - Database instance ID

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### Application Load Balancer Module
**[Quick Jump](#module-quick-links)** | **[Previous: RDS Database](#rds-database-module)** | **[Next: EKS Cluster](#eks-cluster-module)**

Application Load Balancers with advanced routing and SSL/TLS termination.

**Features:**
- HTTP and HTTPS listeners
- Multiple target groups
- Path-based and host-based routing
- SSL/TLS termination
- Multiple SSL certificates support
- Session stickiness
- Health checks with custom configuration

**Example:**

```hcl
module "alb" {
  source = "./modules/alb"

  alb_name           = "production-alb"
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

**Outputs:**
- `alb_arn` - ALB ARN
- `alb_dns_name` - ALB DNS name
- `target_group_arns` - Target group ARNs

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### EKS Cluster Module
**[Quick Jump](#module-quick-links)** | **[Previous: Application Load Balancer](#application-load-balancer-module)** | **[Next: Lambda Function](#lambda-function-module)**

Production-ready Amazon EKS clusters with managed node groups and Fargate support.

**Features:**
- Managed node groups with auto-scaling
- Multiple node group configurations
- Fargate profiles for serverless containers
- IAM Roles for Service Accounts (IRSA)
- EKS add-ons (VPC CNI, CoreDNS, kube-proxy)
- CloudWatch logging
- Secrets encryption with KMS

**Example:**

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "production-eks"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_encryption_key_arn = aws_kms_key.eks.arn

  node_groups = {
    general = {
      desired_size   = 3
      max_size       = 6
      min_size       = 2
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      ami_type       = "AL2_x86_64"
      
      labels = {
        role = "general"
      }
    }
    
    spot = {
      desired_size   = 2
      max_size       = 8
      min_size       = 0
      instance_types = ["t3.large", "t3a.large"]
      capacity_type  = "SPOT"
      disk_size      = 50
      ami_type       = "AL2_x86_64"
      
      labels = {
        role = "spot"
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `cluster_id` - EKS cluster ID
- `cluster_endpoint` - EKS cluster endpoint
- `cluster_certificate_authority_data` - Certificate authority data

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### Lambda Function Module
**[Quick Jump](#module-quick-links)** | **[Previous: EKS Cluster](#eks-cluster-module)** | **[Next: DynamoDB Table](#dynamodb-table-module)**

Deploy serverless functions with full IAM role management, CloudWatch logging, and event triggers.

**Features:**
- Automatic IAM role creation
- VPC support
- Dead letter queues
- Lambda layers
- Event triggers (EventBridge, API Gateway, etc.)
- X-Ray tracing
- Ephemeral storage configuration
- Multiple runtime support

**Example:**

```hcl
module "api_lambda" {
  source = "./modules/lambda"

  function_name = "api-handler"
  runtime       = "python3.11"
  handler       = "app.handler"
  filename      = "function.zip"
  timeout       = 30
  memory_size   = 512

  environment_variables = {
    TABLE_NAME = module.dynamodb.table_name
    API_KEY    = var.api_key
  }

  vpc_config = {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  custom_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Resource = module.dynamodb.table_arn
      }]
    })
  ]

  schedules = {
    daily = {
      schedule_expression = "rate(1 day)"
      description         = "Run daily cleanup"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `function_arn` - Lambda function ARN
- `function_name` - Function name
- `function_invoke_arn` - ARN for invoking the function
- `role_arn` - IAM role ARN

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### DynamoDB Table Module
**[Quick Jump](#module-quick-links)** | **[Previous: Lambda Function](#lambda-function-module)** | **[Next: CloudFront Distribution](#cloudfront-distribution-module)**

Create DynamoDB tables with Global/Local Secondary Indexes, autoscaling, and point-in-time recovery.

**Features:**
- On-demand or provisioned billing
- Global and local secondary indexes
- Autoscaling for provisioned capacity
- Point-in-time recovery
- Streams support
- Server-side encryption
- Global tables (multi-region replication)
- CloudWatch alarms

**Example:**

```hcl
module "users_table" {
  source = "./modules/dynamodb"

  table_name   = "users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "timestamp"

  attributes = [
    {
      name = "userId"
      type = "S"
    },
    {
      name = "timestamp"
      type = "N"
    },
    {
      name = "email"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "EmailIndex"
      hash_key        = "email"
      projection_type = "ALL"
    }
  ]

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery_enabled = true
  deletion_protection_enabled    = true

  ttl_enabled        = true
  ttl_attribute_name = "expiresAt"

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `table_id` - DynamoDB table ID
- `table_arn` - Table ARN
- `stream_arn` - DynamoDB stream ARN

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### CloudFront Distribution Module
**[Quick Jump](#module-quick-links)** | **[Previous: DynamoDB Table](#dynamodb-table-module)** | **[Next: API Gateway](#api-gateway-module)**

Deploy CloudFront distributions with origin access control, custom error pages, and edge functions.

**Features:**
- Multiple origins and origin groups
- Origin Access Control (OAC) for S3
- Cache behaviors with policies
- Lambda@Edge and CloudFront Functions
- Custom error responses
- Geographic restrictions
- SSL/TLS certificates
- Access logging
- WAF integration

**Example:**

```hcl
module "cdn" {
  source = "./modules/cloudfront"

  comment             = "Production CDN"
  default_root_object = "index.html"
  aliases             = ["example.com", "www.example.com"]
  price_class         = "PriceClass_100"

  origins = [
    {
      domain_name              = module.s3_bucket.bucket_regional_domain_name
      origin_id                = "S3-Website"
      origin_access_control_id = module.cdn.origin_access_control_ids["s3-oac"]
    }
  ]

  default_cache_behavior = {
    target_origin_id       = "S3-Website"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
  }

  ordered_cache_behaviors = [
    {
      path_pattern           = "/api/*"
      target_origin_id       = "API-Gateway"
      viewer_protocol_policy = "https-only"
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD"]
      cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_disabled.id
    }
  ]

  origin_access_controls = {
    s3-oac = {
      description      = "OAC for S3 bucket"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  custom_error_responses = [
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]

  acm_certificate_arn      = aws_acm_certificate.cdn.arn
  minimum_protocol_version = "TLSv1.2_2021"

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `distribution_id` - CloudFront distribution ID
- `domain_name` - CloudFront domain name
- `origin_access_control_ids` - OAC IDs

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### API Gateway Module
**[Quick Jump](#module-quick-links)** | **[Previous: CloudFront Distribution](#cloudfront-distribution-module)** | **[Next: ECR Repository](#ecr-repository-module)**

Create REST, HTTP, or WebSocket APIs with custom domains, usage plans, and WAF integration.

**Features:**
- REST, HTTP, and WebSocket API support
- Custom domain names
- API keys and usage plans
- Request validation
- CORS configuration
- Access logging
- X-Ray tracing
- VPC links
- WAF integration

**Example (HTTP API):**

```hcl
module "api" {
  source = "./modules/apigateway"

  name        = "my-api"
  api_type    = "HTTP"
  description = "Production API"

  cors_configuration = {
    allow_origins = ["https://example.com"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["*"]
    max_age       = 300
  }

  stage_name  = "prod"
  auto_deploy = true

  access_log_settings = {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  domain_name     = "api.example.com"
  certificate_arn = aws_acm_certificate.api.arn

  tags = {
    Environment = "production"
  }
}
```

**Example (REST API with Usage Plans):**

```hcl
module "rest_api" {
  source = "./modules/apigateway"

  name     = "rest-api"
  api_type = "REST"

  stage_name = "prod"

  usage_plans = {
    basic = {
      description          = "Basic tier"
      quota_limit          = 10000
      quota_period         = "MONTH"
      throttle_burst_limit = 100
      throttle_rate_limit  = 50
    }
    premium = {
      description          = "Premium tier"
      quota_limit          = 100000
      quota_period         = "MONTH"
      throttle_burst_limit = 500
      throttle_rate_limit  = 200
    }
  }

  api_keys = {
    customer1 = {
      description = "Customer 1 API key"
    }
  }

  usage_plan_keys = {
    customer1_basic = {
      api_key_name    = "customer1"
      usage_plan_name = "basic"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `api_id` - API Gateway ID
- `api_endpoint` - API endpoint URL
- `stage_invoke_url` - Stage invoke URL

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### ECR Repository Module
**[Quick Jump](#module-quick-links)** | **[Previous: API Gateway](#api-gateway-module)** | **[Next: Step Functions](#step-functions-module)**

Manage container image repositories with lifecycle policies and replication.

**Features:**
- Image scanning on push
- Lifecycle policies for image cleanup
- Cross-region replication
- Encryption at rest (KMS or AES256)
- Repository policies
- Pull through cache rules

**Example:**

```hcl
module "app_ecr" {
  source = "./modules/ecr"

  repository_name      = "my-app"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  encryption_type      = "KMS"
  kms_key_arn          = aws_kms_key.ecr.arn

  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowPull"
      Effect = "Allow"
      Principal = {
        AWS = var.allowed_account_ids
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }]
  })

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `repository_arn` - ECR repository ARN
- `repository_url` - Repository URL for pushing images

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### Step Functions Module
**[Quick Jump](#module-quick-links)** | **[Previous: ECR Repository](#ecr-repository-module)** | **[Next: SNS/SQS](#snssqs-module)**

Orchestrate workflows with state machines and EventBridge integration.

**Features:**
- Standard and Express workflows
- CloudWatch Logs integration
- X-Ray tracing
- IAM role management
- EventBridge triggers
- CloudWatch alarms

**Example:**

```hcl
module "order_workflow" {
  source = "./modules/stepfunctions"

  name = "order-processing"
  type = "STANDARD"

  definition = jsonencode({
    Comment = "Order processing workflow"
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type     = "Task"
        Resource = module.validate_lambda.function_arn
        Next     = "ProcessPayment"
      }
      ProcessPayment = {
        Type     = "Task"
        Resource = module.payment_lambda.function_arn
        Next     = "FulfillOrder"
      }
      FulfillOrder = {
        Type     = "Task"
        Resource = module.fulfillment_lambda.function_arn
        End      = true
      }
    }
  })

  custom_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = [
          module.validate_lambda.function_arn,
          module.payment_lambda.function_arn,
          module.fulfillment_lambda.function_arn
        ]
      }]
    })
  ]

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_enabled = true

  event_triggers = {
    order_created = {
      event_pattern = jsonencode({
        source      = ["custom.orders"]
        detail-type = ["Order Created"]
      })
    }
  }

  create_alarms        = true
  alarm_sns_topic_arns = [aws_sns_topic.alerts.arn]

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `state_machine_arn` - Step Functions state machine ARN
- `state_machine_name` - State machine name

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### SNS/SQS Module
**[Quick Jump](#module-quick-links)** | **[Previous: Step Functions](#step-functions-module)** | **[Next: ElastiCache](#elasticache-module)**

Create messaging infrastructure with topics, queues, and subscriptions.

**Features:**
- SNS topics (standard and FIFO)
- SQS queues (standard and FIFO)
- Dead letter queues
- SNS to SQS subscriptions
- Encryption at rest
- Message filtering
- CloudWatch alarms

**Example:**

```hcl
module "messaging" {
  source = "./modules/messaging"

  sns_topics = {
    orders = {
      display_name = "Order Events"
      fifo_topic   = false
    }
    notifications = {
      display_name = "User Notifications"
    }
  }

  sqs_queues = {
    order_processing = {
      visibility_timeout_seconds = 300
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 20
      fifo_queue                 = false
      sqs_managed_sse_enabled    = true
    }
  }

  sqs_dead_letter_queues = {
    order_processing_dlq = {
      message_retention_seconds = 1209600
    }
  }

  sqs_redrive_policies = {
    order_processing = {
      dlq_name          = "order_processing_dlq"
      max_receive_count = 3
    }
  }

  sns_to_sqs_subscriptions = {
    orders_to_processing = {
      topic_name           = "orders"
      queue_name           = "order_processing"
      raw_message_delivery = false
      filter_policy = jsonencode({
        event_type = ["order_created", "order_updated"]
      })
    }
  }

  create_sqs_alarms    = true
  alarm_sns_topic_arns = [aws_sns_topic.alerts.arn]

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `sns_topic_arns` - SNS topic ARNs
- `sqs_queue_urls` - SQS queue URLs
- `sqs_queue_arns` - SQS queue ARNs

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### ElastiCache Module
**[Quick Jump](#module-quick-links)** | **[Previous: SNS/SQS](#snssqs-module)** | **[Next: Route53](#route53-module)**

Deploy Redis or Memcached clusters with encryption and monitoring.

**Features:**
- Redis and Memcached support
- Multi-AZ with automatic failover
- Encryption in transit and at rest
- Redis AUTH support
- Backup and restore
- CloudWatch alarms
- Parameter groups
- Cluster mode support

**Example (Redis):**

```hcl
module "redis" {
  source = "./modules/elasticache"

  engine                     = "redis"
  replication_group_id       = "app-cache"
  description                = "Application cache"
  engine_version             = "7.0"
  node_type                  = "cache.r7g.large"
  num_cache_clusters         = 3
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  kms_key_id                 = aws_kms_key.redis.arn

  parameter_group_family = "redis7"
  parameters = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    }
  ]

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "sun:05:00-sun:07:00"

  create_alarms        = true
  alarm_sns_topic_arns = [aws_sns_topic.alerts.arn]

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `primary_endpoint_address` - Primary endpoint address
- `reader_endpoint_address` - Reader endpoint address

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### Route53 Module
**[Quick Jump](#module-quick-links)** | **[Previous: ElastiCache](#elasticache-module)** | **[Next: WAF](#waf-module)**

Manage DNS zones, records, health checks, and traffic policies.

**Features:**
- Public and private hosted zones
- All record types
- Alias records
- Weighted, latency, geolocation routing
- Health checks
- Traffic policies
- Query logging

**Example:**

```hcl
module "dns" {
  source = "./modules/route53"

  hosted_zones = {
    "example.com" = {
      comment = "Production domain"
    }
    "internal.example.com" = {
      comment = "Internal services"
      vpcs = [
        {
          vpc_id = var.vpc_id
        }
      ]
    }
  }

  records = {
    www = {
      zone_name = "example.com"
      name      = "www"
      type      = "A"
      alias = {
        name                   = module.cdn.domain_name
        zone_id                = module.cdn.hosted_zone_id
        evaluate_target_health = false
      }
    }
    api = {
      zone_name = "example.com"
      name      = "api"
      type      = "A"
      ttl       = 300
      records   = [aws_eip.api.public_ip]
    }
  }

  health_checks = {
    api_health = {
      type              = "HTTPS"
      fqdn              = "api.example.com"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
    }
  }

  create_health_check_alarms = true
  alarm_sns_topic_arns       = [aws_sns_topic.alerts.arn]

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `zone_ids` - Hosted zone IDs
- `zone_name_servers` - Name servers for zones
- `health_check_ids` - Health check IDs

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

### WAF Module
**[Quick Jump](#module-quick-links)** | **[Previous: Route53](#route53-module)** | **[Next: Complete Infrastructure Examples](#complete-infrastructure-examples)**

Protect applications with Web Application Firewall rules.

**Features:**
- Rate limiting
- Geographic restrictions
- IP allow/deny lists
- Managed rule groups (AWS and third-party)
- Custom rules
- Request inspection
- Logging to CloudWatch or S3

**Example:**

```hcl
module "waf" {
  source = "./modules/waf"

  name           = "web-app-firewall"
  description    = "WAF for production API"
  scope          = "REGIONAL"
  default_action = "allow"

  ip_sets = {
    blocked_ips = {
      ip_address_version = "IPV4"
      addresses = [
        "192.0.2.0/24",
        "198.51.100.0/24"
      ]
    }
  }

  rules = [
    {
      name     = "RateLimitRule"
      priority = 1
      action   = "block"
      statement = {
        rate_based = {
          limit              = 2000
          aggregate_key_type = "IP"
        }
      }
    },
    {
      name     = "BlockBadIPs"
      priority = 2
      action   = "block"
      statement = {
        ip_set_reference = {
          ip_set_name = "blocked_ips"
        }
      }
    },
    {
      name            = "AWSManagedRulesCommonRuleSet"
      priority        = 3
      override_action = "none"
      statement = {
        managed_rule_group = {
          vendor_name = "AWS"
          name        = "AWSManagedRulesCommonRuleSet"
        }
      }
    },
    {
      name     = "GeoBlockRule"
      priority = 4
      action   = "block"
      statement = {
        geo_match = {
          country_codes = ["CN", "RU"]
        }
      }
    }
  ]

  logging_configuration = {
    log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  }

  tags = {
    Environment = "production"
  }
}
```

**Outputs:**
- `web_acl_arn` - WAF Web ACL ARN
- `web_acl_capacity` - Capacity units used

**[Back to Module Links](#module-quick-links)** | **[Back to Top](#quick-navigation)**

---

## Complete Infrastructure Examples

**Navigation:** [Back to Top](#quick-navigation) | [View All Modules](#module-quick-links) | [Jump to Best Practices](#best-practices)

### Simple Web Application

This example creates a complete web application infrastructure:

```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}

# Networking
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "${var.project_name}-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  
  enable_nat_gateway = true
  
  tags = local.common_tags
}

# Storage
module "app_bucket" {
  source = "./modules/s3-bucket"

  bucket_name        = "${var.project_name}-assets-${random_id.suffix.hex}"
  versioning_enabled = true
  
  lifecycle_rules = [
    {
      id      = "archive-old-objects"
      enabled = true
      
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
      
      expiration_days = 365
    }
  ]
  
  tags = local.common_tags
}

# Database
module "rds" {
  source = "./modules/rds"

  db_identifier   = "${var.project_name}-db"
  engine          = "postgres"
  engine_version  = "15.4"
  instance_class  = "db.t3.large"

  database_name   = var.db_name
  master_username = var.db_username
  master_password = var.db_password

  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.database.id]

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_encrypted     = true

  multi_az                = true
  backup_retention_period = 14
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true

  tags = local.common_tags
}

# Load Balancer
module "alb" {
  source = "./modules/alb"

  alb_name           = "${var.project_name}-alb"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb.id]
  vpc_id             = module.vpc.vpc_id

  certificate_arn = aws_acm_certificate.main.arn

  target_groups = {
    web = {
      name        = "${var.project_name}-web-tg"
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
    }
  }

  default_target_group_key = "web"

  tags = local.common_tags
}

# Application Servers
module "web_servers" {
  source = "./modules/ec2-instance"
  count  = 3

  instance_name      = "${var.project_name}-web-${count.index + 1}"
  instance_type      = "t3.medium"
  subnet_id          = module.vpc.private_subnet_ids[count.index]
  security_group_ids = [aws_security_group.web.id]
  
  root_volume_size = 30
  
  user_data = templatefile("${path.module}/user-data.sh", {
    db_endpoint = module.rds.db_instance_endpoint
    bucket_name = module.app_bucket.bucket_id
  })
  
  tags = merge(local.common_tags, {
    Role = "web-server"
  })
}

# Local variables
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}
```

**[View More Examples](#microservices-platform-with-eks)** | **[Back to Top](#quick-navigation)**

### Microservices Platform with EKS

**[Previous Example: Simple Web App](#simple-web-application)** | **[Next Example: Serverless Pipeline](#serverless-data-processing-pipeline)**

This example creates a complete microservices platform:

```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "microservices/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Networking
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "microservices-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  
  enable_nat_gateway = true
  
  tags = local.common_tags
}

# Container Registry
module "ecr" {
  source = "./modules/ecr"

  for_each = toset(["user-service", "order-service", "payment-service"])

  repository_name      = each.key
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  
  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })

  tags = local.common_tags
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  cluster_name    = "microservices-cluster"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      desired_size   = 3
      max_size       = 6
      min_size       = 2
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      
      labels = {
        role = "general"
      }
    }
    
    spot = {
      desired_size   = 2
      max_size       = 8
      min_size       = 0
      instance_types = ["t3.large", "t3a.large"]
      capacity_type  = "SPOT"
      
      labels = {
        role = "spot"
      }
    }
  }

  tags = local.common_tags
}

# API Gateway
module "api_gateway" {
  source = "./modules/apigateway"

  name        = "microservices-api"
  api_type    = "HTTP"
  description = "Microservices API Gateway"

  cors_configuration = {
    allow_origins = ["https://*.example.com"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "PATCH"]
    allow_headers = ["*"]
    max_age       = 300
  }

  stage_name  = "prod"
  auto_deploy = true

  tags = local.common_tags
}

# Messaging
module "messaging" {
  source = "./modules/messaging"

  sns_topics = {
    orders     = { display_name = "Order Events" }
    payments   = { display_name = "Payment Events" }
    shipments  = { display_name = "Shipment Events" }
  }

  sqs_queues = {
    order_processing = {
      visibility_timeout_seconds = 300
      message_retention_seconds  = 1209600
    }
    notification_queue = {
      visibility_timeout_seconds = 60
      message_retention_seconds  = 345600
    }
  }

  sqs_dead_letter_queues = {
    order_dlq        = {}
    notification_dlq = {}
  }

  sqs_redrive_policies = {
    order_processing   = { dlq_name = "order_dlq", max_receive_count = 3 }
    notification_queue = { dlq_name = "notification_dlq", max_receive_count = 5 }
  }

  tags = local.common_tags
}

# Cache
module "redis" {
  source = "./modules/elasticache"

  engine                     = "redis"
  replication_group_id       = "app-cache"
  engine_version             = "7.0"
  node_type                  = "cache.r7g.large"
  num_cache_clusters         = 3
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = local.common_tags
}

# DNS
module "dns" {
  source = "./modules/route53"

  hosted_zones = {
    "api.example.com" = {
      comment = "Microservices API"
    }
  }

  records = {
    api = {
      zone_name = "api.example.com"
      name      = "api"
      type      = "A"
      alias = {
        name                   = module.api_gateway.domain_name
        zone_id                = module.api_gateway.domain_hosted_zone_id
        evaluate_target_health = false
      }
    }
  }

  tags = local.common_tags
}

locals {
  common_tags = {
    Environment = "production"
    Project     = "microservices"
    ManagedBy   = "Terraform"
  }
}
```

**[View More Examples](#serverless-data-processing-pipeline)** | **[Back to Top](#quick-navigation)**

### Serverless Data Processing Pipeline

**[Previous Example: Microservices Platform](#microservices-platform-with-eks)** | **[Jump to Best Practices](#best-practices)**

This example creates a serverless data processing pipeline:

```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

# S3 Buckets for Data Pipeline
module "raw_data_bucket" {
  source = "./modules/s3-bucket"

  bucket_name        = "data-pipeline-raw-${random_id.suffix.hex}"
  versioning_enabled = true
  
  lifecycle_rules = [
    {
      id      = "move-to-glacier"
      enabled = true
      
      transitions = [
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    }
  ]

  tags = local.common_tags
}

module "processed_data_bucket" {
  source = "./modules/s3-bucket"

  bucket_name        = "data-pipeline-processed-${random_id.suffix.hex}"
  versioning_enabled = true

  tags = local.common_tags
}

# DynamoDB Table for Metadata
module "metadata_table" {
  source = "./modules/dynamodb"

  table_name   = "data-pipeline-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "jobId"
  range_key    = "timestamp"

  attributes = [
    { name = "jobId", type = "S" },
    { name = "timestamp", type = "N" },
    { name = "status", type = "S" }
  ]

  global_secondary_indexes = [
    {
      name            = "StatusIndex"
      hash_key        = "status"
      range_key       = "timestamp"
      projection_type = "ALL"
    }
  ]

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = local.common_tags
}

# Lambda Functions
module "ingestion_lambda" {
  source = "./modules/lambda"

  function_name = "data-ingestion"
  runtime       = "python3.11"
  handler       = "index.handler"
  filename      = "lambda/ingestion.zip"
  timeout       = 300
  memory_size   = 1024

  environment_variables = {
    RAW_BUCKET    = module.raw_data_bucket.bucket_id
    METADATA_TABLE = module.metadata_table.table_name
  }

  custom_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject"
          ]
          Resource = "${module.raw_data_bucket.bucket_arn}/*"
        },
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"
          ]
          Resource = module.metadata_table.table_arn
        }
      ]
    })
  ]

  tags = local.common_tags
}

module "processing_lambda" {
  source = "./modules/lambda"

  function_name = "data-processing"
  runtime       = "python3.11"
  handler       = "index.handler"
  filename      = "lambda/processing.zip"
  timeout       = 900
  memory_size   = 3008

  environment_variables = {
    RAW_BUCKET       = module.raw_data_bucket.bucket_id
    PROCESSED_BUCKET = module.processed_data_bucket.bucket_id
    METADATA_TABLE   = module.metadata_table.table_name
  }

  custom_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject"
          ]
          Resource = "${module.raw_data_bucket.bucket_arn}/*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject"
          ]
          Resource = "${module.processed_data_bucket.bucket_arn}/*"
        },
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:GetItem"
          ]
          Resource = module.metadata_table.table_arn
        }
      ]
    })
  ]

  tags = local.common_tags
}

# Step Functions Workflow
module "data_pipeline" {
  source = "./modules/stepfunctions"

  name = "data-processing-pipeline"
  type = "STANDARD"

  definition = jsonencode({
    Comment = "Data processing pipeline"
    StartAt = "IngestData"
    States = {
      IngestData = {
        Type     = "Task"
        Resource = module.ingestion_lambda.function_arn
        Next     = "ProcessData"
        Retry = [{
          ErrorEquals     = ["States.ALL"]
          IntervalSeconds = 2
          MaxAttempts     = 3
          BackoffRate     = 2.0
        }]
      }
      ProcessData = {
        Type     = "Task"
        Resource = module.processing_lambda.function_arn
        Next     = "NotifyCompletion"
        Retry = [{
          ErrorEquals     = ["States.ALL"]
          IntervalSeconds = 5
          MaxAttempts     = 2
          BackoffRate     = 2.0
        }]
      }
      NotifyCompletion = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = module.notifications.sns_topic_arns["pipeline_events"]
          Message  = "Data pipeline completed successfully"
        }
        End = true
      }
    }
  })

  custom_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "lambda:InvokeFunction"
          Resource = [
            module.ingestion_lambda.function_arn,
            module.processing_lambda.function_arn
          ]
        },
        {
          Effect   = "Allow"
          Action   = "sns:Publish"
          Resource = module.notifications.sns_topic_arns["pipeline_events"]
        }
      ]
    })
  ]

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  event_triggers = {
    scheduled = {
      schedule_expression = "rate(1 hour)"
      description         = "Run pipeline every hour"
    }
  }

  tags = local.common_tags
}

# Notifications
module "notifications" {
  source = "./modules/messaging"

  sns_topics = {
    pipeline_events = {
      display_name = "Pipeline Events"
    }
  }

  tags = local.common_tags
}

# API for triggering pipeline
module "api" {
  source = "./modules/apigateway"

  name        = "data-pipeline-api"
  api_type    = "HTTP"
  description = "API for data pipeline"

  stage_name  = "prod"
  auto_deploy = true

  tags = local.common_tags
}

locals {
  common_tags = {
    Environment = "production"
    Project     = "data-pipeline"
    ManagedBy   = "Terraform"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}
```

**[Back to Examples](#complete-infrastructure-examples)** | **[Back to Top](#quick-navigation)**

---

## Project Structure

**Navigation:** [Back to Top](#quick-navigation) | [Jump to Best Practices](#best-practices)

```
aws-terraform-modules/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── s3-bucket/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── ec2-instance/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── rds/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── alb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── eks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── lambda/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── dynamodb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── cloudfront/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── apigateway/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── ecr/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── stepfunctions/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── messaging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── elasticache/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── route53/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── waf/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── examples/
│   ├── simple-web-app/
│   ├── microservices-platform/
│   └── data-processing-pipeline/
├── README.md
├── CHANGELOG.md
└── LICENSE
```

**[Back to Top](#quick-navigation)**

---

## Best Practices

**Navigation:** [Back to Top](#quick-navigation) | [Security](#security) | [Monitoring](#monitoring--observability) | [Cost](#cost-optimization) | [Deployment](#deployment)

### Security

#### 1. Encryption
- **Data at Rest**: All modules support encryption at rest by default
- **Data in Transit**: Enable TLS/SSL for all network communications
- **KMS Keys**: Use customer-managed KMS keys for sensitive data
- **Secrets**: Never hardcode credentials; use AWS Secrets Manager or Systems Manager Parameter Store

```hcl
# Example: Using KMS for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for encrypting resources"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

module "rds" {
  source = "./modules/rds"
  
  storage_encrypted = true
  kms_key_id        = aws_kms_key.main.arn
  # ... other configuration
}
```

#### 2. Network Security
- **VPC Isolation**: Deploy resources in private subnets when possible
- **Security Groups**: Follow least privilege principle
- **NACLs**: Use network ACLs for additional layer of security
- **VPC Endpoints**: Use VPC endpoints to keep traffic within AWS network

```hcl
# Example: Restrictive security group
resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTPS from ALB only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}
```

#### 3. IAM Best Practices
- **Least Privilege**: Grant minimum required permissions
- **Role-Based Access**: Use IAM roles instead of access keys
- **Policy Conditions**: Use conditions in policies for additional security
- **MFA**: Require MFA for sensitive operations

### Monitoring & Observability

#### 1. CloudWatch Logs
```hcl
# All modules support CloudWatch logging
module "lambda" {
  source = "./modules/lambda"
  
  create_log_group    = true
  log_retention_days  = 30
  # ... other configuration
}
```

#### 2. CloudWatch Alarms
```hcl
# Enable alarms for critical metrics
module "dynamodb" {
  source = "./modules/dynamodb"
  
  create_alarms        = true
  alarm_sns_topic_arns = [aws_sns_topic.alerts.arn]
  # ... other configuration
}
```

#### 3. X-Ray Tracing
```hcl
# Enable distributed tracing
module "lambda" {
  source = "./modules/lambda"
  
  tracing_mode = "Active"
  # ... other configuration
}

module "api_gateway" {
  source = "./modules/apigateway"
  
  xray_tracing_enabled = true
  # ... other configuration
}
```

**[Back to Best Practices](#best-practices)** | **[Back to Top](#quick-navigation)**

### Cost Optimization

**[Jump to Section](#best-practices)** | **[View Detailed Cost Guide](#cost-considerations)**

#### 1. Right-Sizing
- Start with smaller instance types and scale as needed
- Use AWS Compute Optimizer recommendations
- Monitor utilization metrics regularly

#### 2. Auto-Scaling
```hcl
# DynamoDB auto-scaling
module "dynamodb" {
  source = "./modules/dynamodb"
  
  billing_mode       = "PROVISIONED"
  read_capacity      = 5
  write_capacity     = 5
  autoscaling_enabled = true
  autoscaling_read_max_capacity  = 100
  autoscaling_write_max_capacity = 100
  # ... other configuration
}
```

#### 3. Lifecycle Policies
```hcl
# S3 lifecycle rules
module "s3_bucket" {
  source = "./modules/s3-bucket"
  
  lifecycle_rules = [
    {
      id      = "cost-optimization"
      enabled = true
      
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      
      expiration_days = 365
    }
  ]
}
```

#### 4. Reserved Capacity
- Use Savings Plans or Reserved Instances for predictable workloads
- Reserve RDS instances for production databases
- Consider Compute Savings Plans for flexible compute

### Deployment

#### 1. Environment Separation
```
project/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
```

#### 2. Remote State
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

#### 3. Terraform Workflow
```bash
# Initialize
terraform init

# Validate
terraform validate

# Format
terraform fmt -recursive

# Plan
terraform plan -out=tfplan

# Review plan
terraform show tfplan

# Apply
terraform apply tfplan

# Verify
terraform show
```

**[Back to Best Practices](#best-practices)** | **[Back to Top](#quick-navigation)**

#### 4. Tagging Strategy

**[Jump to Section](#best-practices)**
```hcl
# Consistent tagging across all resources
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner
    Compliance  = var.compliance_level
  }
}

# Use default_tags in provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
```

**[Back to Best Practices](#best-practices)** | **[Back to Top](#quick-navigation)**

---

## Testing

**Navigation:** [Back to Top](#quick-navigation) | [Jump to Cost Guide](#cost-considerations)

### Validation and Testing Workflow

#### 1. Syntax Validation
```bash
# Validate Terraform syntax
terraform validate

# Format code
terraform fmt -recursive -check

# Check for security issues with tfsec
tfsec .

# Check for best practices with checkov
checkov -d .
```

#### 2. Plan Review
```bash
# Generate and review plan
terraform plan -out=tfplan

# Show plan in JSON format for automated review
terraform show -json tfplan | jq '.'

# Check for destructive changes
terraform plan | grep -E "destroy|replace"
```

#### 3. Automated Testing
```hcl
# Example: Terratest
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_name": "test-vpc",
            "vpc_cidr": "10.0.0.0/16",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

#### 4. Integration Testing
```bash
# Test in development environment first
cd environments/dev
terraform init
terraform plan
terraform apply -auto-approve

# Run smoke tests
./scripts/smoke-test.sh

# Clean up
terraform destroy -auto-approve
```

**[Back to Testing](#testing)** | **[Back to Top](#quick-navigation)**

---

## Cost Considerations

**Navigation:** [Back to Top](#quick-navigation) | [Pricing Table](#estimated-monthly-costs-us-east-1-region) | [Optimization Tips](#cost-optimization-strategies)

### Estimated Monthly Costs (us-east-1 region)

#### Infrastructure Components

| Module | Basic Configuration | Production Configuration |
|--------|---------------------|--------------------------|
| **VPC** | ~$32/month (1 NAT Gateway) | ~$96/month (3 NAT Gateways) |
| **S3** | ~$0.023/GB stored | Varies by usage + requests |
| **EC2 (t3.medium)** | ~$30/month | ~$90/month (3 instances) |
| **RDS (PostgreSQL)** | ~$30/month (db.t3.small) | ~$290/month (Multi-AZ db.r6g.large) |
| **ALB** | ~$23/month base + data | ~$23/month + $0.008/LCU-hour |
| **EKS** | ~$73/month (control plane) | ~$73/month + node costs |
| **Lambda** | Free tier: 1M requests | $0.20 per 1M requests after |
| **DynamoDB** | Free tier: 25 GB | Pay-per-request varies |
| **CloudFront** | ~$0.085/GB (first 10 TB) | Varies by traffic |
| **API Gateway** | $3.50 per million (HTTP) | REST: $3.50/million + data |
| **ECR** | $0.10/GB/month | Varies by image storage |
| **Step Functions** | $25 per 1M state transitions | Enterprise: varies |
| **SNS** | $0.50 per 1M requests | Varies by usage |
| **SQS** | Free tier: 1M requests | $0.40 per 1M requests after |
| **ElastiCache** | ~$13/month (t3.micro) | ~$340/month (r7g.large Multi-AZ) |
| **Route53** | $0.50 per hosted zone/month | + $0.40 per 1M queries |
| **WAF** | $5/month per Web ACL | + $1/month per rule |

**Note:** Prices are approximate and vary by region and usage patterns.

**[Back to Cost Guide](#cost-considerations)** | **[Back to Top](#quick-navigation)**

#### Cost Optimization Strategies

**[Jump to Section](#cost-considerations)**

**1. Development/Test Environments**
```hcl
# Use smaller instances for non-production
variable "instance_type" {
  type = map(string)
  default = {
    dev     = "t3.small"
    staging = "t3.medium"
    prod    = "t3.large"
  }
}

# Schedule start/stop for dev environments
resource "aws_instance_schedule" "dev" {
  count = var.environment == "dev" ? 1 : 0
  # Stop instances at night and weekends
}
```

**2. Serverless First**
```hcl
# Prefer Lambda over EC2 for variable workloads
# DynamoDB on-demand over RDS for unpredictable traffic
# Fargate over EC2 for containers with variable usage
```

**3. Storage Optimization**
```hcl
# Implement lifecycle policies
module "s3_bucket" {
  source = "./modules/s3-bucket"
  
  lifecycle_rules = [
    {
      id      = "optimize-costs"
      enabled = true
      
      transitions = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 90, storage_class = "GLACIER" },
        { days = 180, storage_class = "DEEP_ARCHIVE" }
      ]
      
      expiration_days = 365
    }
  ]
}
```

**4. Spot Instances**
```hcl
# Use Spot instances for fault-tolerant workloads
module "eks" {
  source = "./modules/eks"
  
  node_groups = {
    spot = {
      capacity_type  = "SPOT"
      instance_types = ["t3.large", "t3a.large", "t2.large"]
      # Multiple instance types increase availability
    }
  }
}
```

**5. Reserved Capacity**
```bash
# For predictable workloads, commit to:
# - RDS Reserved Instances (1-3 years): ~40-60% savings
# - EC2 Savings Plans: ~72% savings
# - ElastiCache Reserved Nodes: ~30-55% savings
```

**[Back to Cost Guide](#cost-considerations)** | **[Back to Top](#quick-navigation)**

### Cost Monitoring

**[Jump to Section](#cost-considerations)**

```hcl
# Enable cost allocation tags
provider "aws" {
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      CostCenter  = var.cost_center
      Owner       = var.owner
    }
  }
}

# Set up billing alarms
resource "aws_cloudwatch_metric_alarm" "billing" {
  alarm_name          = "monthly-bill-exceeds-budget"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600  # 6 hours
  statistic           = "Maximum"
  threshold           = var.monthly_budget
  alarm_description   = "Alert when monthly charges exceed budget"
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]

  dimensions = {
    Currency = "USD"
  }
}
```

**[Back to Cost Guide](#cost-considerations)** | **[Back to Top](#quick-navigation)**

---

## Contributing

**Navigation:** [Back to Top](#quick-navigation) | [How to Contribute](#how-to-contribute) | [Guidelines](#development-guidelines)

We welcome contributions! Please follow these guidelines:

### How to Contribute

1. **Fork the Repository**
   ```bash
   git clone https://github.com/jaaparjazzery/aws-terraform-modules.git
   cd aws-terraform-modules
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make Your Changes**
   - Follow the existing code style
   - Update documentation
   - Add examples if applicable
   - Write tests for new functionality

4. **Test Your Changes**
   ```bash
   terraform fmt -recursive
   terraform validate
   tfsec .
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m 'Add amazing feature'
   ```

6. **Push to Your Fork**
   ```bash
   git push origin feature/amazing-feature
   ```

7. **Open a Pull Request**
   - Provide a clear description of changes
   - Reference any related issues
   - Include before/after examples if applicable

### Development Guidelines

#### Code Style
- Follow [HashiCorp's Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- Use consistent naming conventions
- Add meaningful comments for complex logic
- Keep modules focused and reusable

#### Documentation
- Update README.md for module changes
- Include usage examples
- Document all variables and outputs
- Add inline comments where necessary

#### Testing
- Test all changes in a development environment
- Validate with `terraform validate`
- Format with `terraform fmt`
- Run security scans with `tfsec` or `checkov`

#### Version Control
- Write clear, descriptive commit messages
- Reference issue numbers in commits
- Keep commits focused and atomic
- Squash commits before merging if needed

### Pull Request Process

1. Ensure all tests pass
2. Update documentation
3. Add yourself to CONTRIBUTORS.md
4. Request review from maintainers
5. Address review feedback
6. Maintainer will merge once approved

### Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow

**[Back to Contributing](#contributing)** | **[Back to Top](#quick-navigation)**

---

## Versioning

**Navigation:** [Back to Top](#quick-navigation)

We use [Semantic Versioning](http://semver.org/) for versioning:

- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality
- **PATCH** version for backwards-compatible bug fixes

### Version History

See [CHANGELOG.md](CHANGELOG.md) for a detailed version history.

### Upgrading

When upgrading between major versions:

1. Review the CHANGELOG for breaking changes
2. Update your Terraform configuration
3. Run `terraform plan` to review changes
4. Test in a non-production environment first
5. Apply changes to production

**[Back to Versioning](#versioning)** | **[Back to Top](#quick-navigation)**

---

## License

**Navigation:** [Back to Top](#quick-navigation)

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### MIT License Summary

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.

**[Back to Top](#quick-navigation)**

---

## Support

**Navigation:** [Back to Top](#quick-navigation) | [Documentation](#documentation) | [Getting Help](#getting-help) | [Issues](#reporting-issues)

### Documentation

- **Module Documentation**: Each module has its own README with detailed usage
- **Examples**: Check the `examples/` directory for complete implementations
- **AWS Documentation**: [AWS Documentation](https://docs.aws.amazon.com/)
- **Terraform Documentation**: [Terraform Registry](https://registry.terraform.io/)

### Getting Help

- 📖 [Documentation](https://github.com/jaaparjazzery/aws-terraform-modules/wiki)
- 🐛 [Issue Tracker](https://github.com/jaaparjazzery/aws-terraform-modules/issues)
- 💬 [Discussions](https://github.com/jaaparjazzery/aws-terraform-modules/discussions)
- 📧 Email: support@example.com

### Reporting Issues

When reporting issues, please include:

1. **Environment Information**
   - Terraform version
   - AWS provider version
   - Operating system
   - Module version

2. **Reproduction Steps**
   - Minimal configuration that reproduces the issue
   - Steps to trigger the problem
   - Expected vs actual behavior

3. **Logs and Output**
   - Terraform plan/apply output
   - Error messages
   - Debug logs if applicable

### Feature Requests

We love feature requests! When submitting:

1. Check if the feature already exists
2. Provide a clear use case
3. Describe the expected behavior
4. Consider submitting a pull request

## Acknowledgments

- **HashiCorp** for creating Terraform
- **Amazon Web Services** for comprehensive cloud services
- **Open Source Community** for inspiration and best practices
- **Contributors** for making this project better

**[Back to Top](#quick-navigation)**

---

## Additional Resources

**Navigation:** [Back to Top](#quick-navigation) | [Learning](#learning-resources) | [Related Projects](#related-projects) | [Community](#community)

### Learning Resources

- [Terraform Getting Started Guide](https://learn.hashicorp.com/terraform)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

### Related Projects

- [terraform-aws-modules](https://github.com/terraform-aws-modules)
- [gruntwork-io/terragrunt](https://github.com/gruntwork-io/terragrunt)
- [bridgecrewio/checkov](https://github.com/bridgecrewio/checkov)
- [aquasecurity/tfsec](https://github.com/aquasecurity/tfsec)

### Community

- [HashiCorp Community Forum](https://discuss.hashicorp.com/c/terraform-core)
- [AWS Subreddit](https://www.reddit.com/r/aws/)
- [DevOps Subreddit](https://www.reddit.com/r/devops/)
- [Infrastructure as Code Slack](https://invite.slack.golevelup.com/)

## Roadmap

### Current Focus

- ✅ Core infrastructure modules (VPC, S3, EC2, RDS, ALB, EKS)
- ✅ Serverless modules (Lambda, API Gateway, Step Functions)
- ✅ Data storage modules (DynamoDB, ElastiCache, ECR)
- ✅ Networking modules (CloudFront, Route53, WAF)
- ✅ Messaging modules (SNS, SQS)

### Future Enhancements

#### Q2 2025
- [ ] Amazon Aurora Serverless module
- [ ] AWS Backup module
- [ ] Amazon Kinesis module
- [ ] AWS Glue module
- [ ] Amazon Athena module

#### Q3 2025
- [ ] Amazon OpenSearch module
- [ ] Amazon EMR module
- [ ] AWS Batch module
- [ ] Amazon EFS module
- [ ] AWS Transfer Family module

#### Q4 2025
- [ ] Amazon SageMaker module
- [ ] Amazon Bedrock module
- [ ] AWS App Runner module
- [ ] Amazon Lightsail module
- [ ] AWS Amplify module

### Long-term Vision

- Comprehensive coverage of all major AWS services
- Automated testing and validation
- CI/CD integration examples
- Multi-cloud support (Azure, GCP)
- Cost optimization tooling
- Compliance and security scanning
- Migration guides and tools

**[Back to Roadmap](#roadmap)** | **[Back to Top](#quick-navigation)**

---

## FAQ

**Navigation:** [Back to Top](#quick-navigation) | [General Questions](#general-questions) | [Technical Questions](#technical-questions)

### General Questions

**Q: Are these modules production-ready?**
A: Yes, all modules follow AWS and Terraform best practices and include security, monitoring, and high availability features.

**Q: Can I use these modules in my commercial project?**
A: Yes, the modules are licensed under MIT, allowing commercial use.

**Q: How do I stay updated with changes?**
A: Watch the repository on GitHub and review the CHANGELOG.md for updates.

### Technical Questions

**Q: Which Terraform version should I use?**
A: We recommend Terraform >= 1.0 and AWS Provider >= 5.0.

**Q: Can I customize the modules?**
A: Absolutely! Modules are designed to be flexible. You can fork and modify them or use variables to customize behavior.

**Q: How do I handle sensitive data like passwords?**
A: Use AWS Secrets Manager, Systems Manager Parameter Store, or Terraform sensitive variables. Never commit secrets to version control.

**Q: What about multi-region deployments?**
A: Use provider aliases to deploy resources across multiple regions. See examples for multi-region configurations.

**Q: How do I migrate existing infrastructure?**
A: Use `terraform import` to bring existing resources under Terraform management. See [Terraform Import Guide](https://www.terraform.io/docs/cli/import/index.html).

**[Back to FAQ](#faq)** | **[Back to Top](#quick-navigation)**

---

## Security

**Navigation:** [Back to Top](#quick-navigation) | [Reporting Issues](#reporting-security-issues) | [Best Practices](#security-best-practices)

### Reporting Security Issues

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, email security@example.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if available)

We will respond within 48 hours and work with you to address the issue.

### Security Best Practices

1. **Keep Dependencies Updated**
   ```bash
   # Update Terraform
   terraform init -upgrade
   
   # Check for security issues
   tfsec .
   checkov -d .
   ```

2. **Use Least Privilege**
   - Minimize IAM permissions
   - Use resource-specific policies
   - Implement MFA where possible

3. **Enable Encryption**
   - Enable encryption at rest for all storage
   - Use TLS for data in transit
   - Rotate encryption keys regularly

4. **Monitor and Audit**
   - Enable CloudTrail logging
   - Set up CloudWatch alarms
   - Review logs regularly

5. **Secrets Management**
   - Use AWS Secrets Manager
   - Never commit secrets to git
   - Rotate secrets regularly

**[Back to Security](#security)** | **[Back to Top](#quick-navigation)**

---

For questions, feedback, or support, please [open an issue](https://github.com/jaaparjazzery/aws-terraform-modules/issues) or [start a discussion](https://github.com/jaaparjazzery/aws-terraform-modules/discussions).

**[Back to Top](#quick-navigation)**


Happy Terraforming! 🚀
