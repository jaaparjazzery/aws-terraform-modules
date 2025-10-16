terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

module "vpc" {
  source = "../../modules/vpc"

  vpc_name           = "${var.project_name}-vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  enable_nat_gateway = true
  
  tags = {
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
}

resource "aws_kms_key" "eks" {
  description             = "EKS encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.eks_cluster_version
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_encryption_key_arn = aws_kms_key.eks.arn

  node_groups = {
    general = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      ami_type       = "AL2_x86_64"
      
      labels = {
        role = "general"
      }
    }
  }

  cluster_addons = {
    vpc-cni = {}
    coredns = {}
    kube-proxy = {}
  }
}

resource "aws_kms_key" "rds" {
  description             = "RDS encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
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

  allocated_storage = 50
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  multi_az                = var.environment == "production"
  backup_retention_period = 7
  
  deletion_protection = false
  skip_final_snapshot = true
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Database security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
