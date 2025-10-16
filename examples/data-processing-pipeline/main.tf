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
  
  enable_nat_gateway = true
}

module "raw_data_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name        = "${var.project_name}-raw-${random_id.suffix.hex}"
  versioning_enabled = true
  
  lifecycle_rules = [
    {
      id      = "archive-raw-data"
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
    }
  ]
}

module "processed_data_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name        = "${var.project_name}-processed-${random_id.suffix.hex}"
  versioning_enabled = true
}

resource "aws_kms_key" "rds" {
  description             = "RDS encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

module "rds" {
  source = "../../modules/rds"

  db_identifier   = "${var.project_name}-metadata"
  engine          = "postgres"
  engine_version  = "15.4"
  instance_class  = var.db_instance_class

  database_name   = var.db_name
  master_username = var.db_username
  master_password = var.db_password

  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.database.id]

  allocated_storage = 50
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true
}

module "coordinator" {
  source = "../../modules/ec2-instance"

  instance_name      = "${var.project_name}-coordinator"
  instance_type      = var.coordinator_instance_type
  subnet_id          = module.vpc.private_subnet_ids[0]
  security_group_ids = [aws_security_group.coordinator.id]
  
  root_volume_size = 30
}

resource "aws_security_group" "coordinator" {
  name        = "${var.project_name}-coordinator-sg"
  description = "Coordinator security group"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Database security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.coordinator.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
