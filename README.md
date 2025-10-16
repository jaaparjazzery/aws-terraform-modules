# AWS Terraform Modules Collection

A comprehensive collection of production-ready Terraform modules for AWS infrastructure. These modules follow AWS and HashiCorp best practices, with security-first defaults and extensive customization options.

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Provider%20%3E%3D4.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

##  Available Modules

### 1. VPC Module
Complete networking infrastructure with public/private subnets, NAT gateways, and route tables.

**Features:**
- Multi-AZ subnet configuration
- NAT Gateway for private subnet internet access
- Internet Gateway for public subnets
- Customizable CIDR blocks
- DNS support enabled by default

[View Module Documentation →](modules/vpc/README.md)

---

### 2. S3 Bucket Module
Secure S3 buckets with encryption, versioning, and lifecycle management.

**Features:**
- Server-side encryption (AES256 or KMS)
- Versioning support
- Public access blocking by default
- Lifecycle rules for storage tiering
- Access logging and CORS configuration

[View Module Documentation →](modules/s3-bucket/README.md)

---

### 3. EC2 Instance Module
Flexible EC2 instances with automatic AMI lookup and advanced configuration options.

**Features:**
- Automatic latest AMI selection
- Multiple EBS volumes support
- IMDSv2 enforcement for security
- Elastic IP support
- User data and IAM instance profiles
- Detailed monitoring options

[View Module Documentation →](modules/ec2-instance/README.md)

---

### 4. RDS Database Module
Managed database instances with high availability and backup configurations.

**Features:**
- Support for PostgreSQL, MySQL, MariaDB, and more
- Multi-AZ deployments
- Read replica support
- Automated backups with configurable retention
- Performance Insights
- Enhanced monitoring
- Encryption at rest

[View Module Documentation →](modules/rds/README.md)

---

### 5. Application Load Balancer Module
Application Load Balancers with advanced routing and SSL/TLS termination.

**Features:**
- HTTP and HTTPS listeners
- Multiple target groups
- Path-based and host-based routing
- SSL/TLS termination
- Multiple SSL certificates support
- Session stickiness
- Health checks with custom configuration

[View Module Documentation →](modules/alb/README.md)

---

### 6. EKS Cluster Module
Production-ready Amazon EKS clusters with managed node groups and Fargate support.

**Features:**
- Managed node groups with auto-scaling
- Multiple node group configurations
- Fargate profiles for serverless containers
- IAM Roles for Service Accounts (IRSA)
- EKS add-ons (VPC CNI, CoreDNS, kube-proxy)
- CloudWatch logging
- Secrets encryption with KMS

[View Module Documentation →](modules/eks/README.md)

---

##  Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS Account with necessary permissions

### Installation

Clone this repository:

```bash
git clone https://github.com/jaaparjazzery/aws-terraform-modules.git
cd aws-terraform-modules
```

### Basic Usage Example

Here's a simple example that creates a complete infrastructure:

```hcl
# Configure AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create VPC
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

# Create S3 Bucket
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

# Create EC2 Instance
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

# Random ID for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

##  Complete Infrastructure Example

Here's a more comprehensive example showing how modules work together:

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
}

# Networking
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "${var.project_name}-vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  enable_nat_gateway = true
  
  tags = local.common_tags
}

# Database
module "rds" {
  source = "./modules/rds"

  db_identifier   = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.large"

  database_name   = var.db_name
  master_username = var.db_username
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

  tags = local.common_tags
}

# Application Load Balancer
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
      
      stickiness = {
        type            = "lb_cookie"
        cookie_duration = 86400
        enabled         = true
      }
    }
  }

  default_target_group_key = "web"

  tags = local.common_tags
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  cluster_name    = "${var.project_name}-eks"
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

  tags = local.common_tags
}

# Local variables
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
```

## 📁 Project Structure

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
│   └── eks/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── examples/
│   ├── simple-web-app/
│   ├── microservices-platform/
│   └── data-processing-pipeline/
├── README.md
└── LICENSE
```

##  Security Best Practices

All modules in this collection follow security best practices:

###  Encryption
- Data encrypted at rest by default
- KMS key support for enhanced security
- SSL/TLS for data in transit

###  Network Security
- Private subnets for databases and applications
- Security groups with least privilege principles
- VPC endpoints for AWS services (where applicable)

###  IAM
- IAM roles with minimal required permissions
- Support for IAM Roles for Service Accounts (IRSA) in EKS
- No hardcoded credentials

###  Monitoring & Logging
- CloudWatch Logs integration
- VPC Flow Logs support
- S3 access logging
- Enhanced monitoring options

###  High Availability
- Multi-AZ deployments
- Auto-scaling capabilities
- Health checks and automatic recovery

##  Testing

Each module should be tested before production use. Example testing workflow:

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan -out=tfplan

# Review the plan carefully
terraform show tfplan

# Apply changes
terraform apply tfplan

# Verify resources
terraform show

# Clean up (when done testing)
terraform destroy
```

##  Cost Considerations

### Cost Optimization Tips:

1. **Use Spot Instances** for non-critical workloads (EKS, EC2)
2. **Enable S3 Lifecycle Policies** to transition objects to cheaper storage classes
3. **Right-size instances** based on actual usage
4. **Use NAT Gateway wisely** - consider one per AZ vs shared
5. **Enable RDS storage autoscaling** to avoid over-provisioning
6. **Use Fargate for EKS** for variable workloads
7. **Schedule start/stop** for non-production environments

### Estimated Monthly Costs (us-east-1):

| Module | Basic Config | Production Config |
|--------|-------------|-------------------|
| VPC | ~$32/month (1 NAT Gateway) | ~$96/month (3 NAT Gateways) |
| S3 Bucket | ~$0.023/GB | Varies by usage |
| EC2 (t3.medium) | ~$30/month | ~$90/month (3 instances) |
| RDS (db.t3.small) | ~$30/month | ~$290/month (Multi-AZ db.r6g.large) |
| ALB | ~$23/month | ~$23/month + data transfer |
| EKS | ~$73/month (control plane) | ~$73/month + node costs |

*Note: Prices are approximate and vary by region and usage*

##  Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines:

- Follow [HashiCorp's Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- Include comprehensive README documentation
- Add examples for new features
- Test all changes thoroughly
- Update CHANGELOG.md

##  Versioning

We use [SemVer](http://semver.org/) for versioning. For available versions, see the [tags on this repository](https://github.com/jaaparjazzery/aws-terraform-modules/tags).

##  License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

##  Acknowledgments

- HashiCorp for Terraform
- AWS for comprehensive cloud services
- The open-source community for inspiration and best practices

##  Support

-  [Documentation](https://github.com/jaaparjazzery/aws-terraform-modules/wiki)
-  [Issue Tracker](https://github.com/jaaparjazzery/aws-terraform-modules/issues)
-  [Discussions](https://github.com/jaaparjazzery/aws-terraform-modules/discussions)

##  Roadmap

Future modules planned:

- [ ] Lambda Function Module
- [ ] DynamoDB Table Module
- [ ] CloudFront Distribution Module
- [ ] API Gateway Module
- [ ] ECR Repository Module
- [ ] Step Functions Module
- [ ] SNS/SQS Module
- [ ] ElastiCache Module
- [ ] Route53 Module
- [ ] WAF Module

##  Star History

If you find this project useful, please consider giving it a star! 

---

For questions or feedback, please open an issue or start a discussion.
