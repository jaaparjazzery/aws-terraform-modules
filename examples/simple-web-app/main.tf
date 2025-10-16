terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Example     = "simple-web-app"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_id" "suffix" {
  byte_length = 4
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name           = "${var.project_name}-vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-rds-key"
  }
}

module "rds" {
  source = "../../modules/rds"

  db_identifier   = "${var.project_name}-db"
  engine          = "postgres"
  engine_version  = "15.4"
  instance_class  = var.db_instance_class

  database_name   = var.db_name
  master_username = var.db_username
  master_password = var.db_password

  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.database.id]

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  multi_az                = var.environment == "production"
  backup_retention_period = var.environment == "production" ? 14 : 7
  
  deletion_protection = var.environment == "production"
  skip_final_snapshot = var.environment != "production"

  tags = {
    Name = "${var.project_name}-database"
  }
}

module "assets_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name        = "${var.project_name}-assets-${random_id.suffix.hex}"
  versioning_enabled = true
  
  tags = {
    Name = "${var.project_name}-assets"
  }
}

module "alb" {
  source = "../../modules/alb"

  alb_name           = "${var.project_name}-alb"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb.id]
  vpc_id             = module.vpc.vpc_id

  enable_http_listener = true
  
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
        unhealthy_threshold = 3
      }
      
      stickiness = {
        type            = "lb_cookie"
        cookie_duration = 86400
        enabled         = true
      }
    }
  }

  default_target_group_key = "web"
}

module "web_server" {
  source = "../../modules/ec2-instance"
  count  = var.web_server_count

  instance_name      = "${var.project_name}-web-${count.index + 1}"
  instance_type      = var.web_instance_type
  subnet_id          = element(module.vpc.private_subnet_ids, count.index)
  security_group_ids = [aws_security_group.web.id]
  
  root_volume_size = 20
  
  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
