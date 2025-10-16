# AWS VPC Terraform Module

This module creates a complete AWS VPC with public and private subnets across multiple availability zones.

## Features

- VPC with customizable CIDR block
- Public and private subnets across multiple AZs
- Internet Gateway for public subnet access
- NAT Gateways for private subnet internet access (optional)
- Properly configured route tables
- DNS support enabled by default

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "my-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  
  enable_nat_gateway = true
  
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_name | Name of the VPC | string | n/a | yes |
| vpc_cidr | CIDR block for VPC | string | "10.0.0.0/16" | no |
| availability_zones | List of availability zones | list(string) | n/a | yes |
| public_subnet_cidrs | CIDR blocks for public subnets | list(string) | ["10.0.1.0/24", "10.0.2.0/24"] | no |
| private_subnet_cidrs | CIDR blocks for private subnets | list(string) | ["10.0.10.0/24", "10.0.11.0/24"] | no |
| enable_nat_gateway | Enable NAT Gateway for private subnets | bool | true | no |
| enable_dns_hostnames | Enable DNS hostnames in the VPC | bool | true | no |
| enable_dns_support | Enable DNS support in the VPC | bool | true | no |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| public_subnet_ids | IDs of public subnets |
| private_subnet_ids | IDs of private subnets |
| nat_gateway_ids | IDs of NAT Gateways |
| internet_gateway_id | ID of Internet Gateway |

