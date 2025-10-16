# Simple Web Application Example

A complete three-tier web application infrastructure.

## Architecture
- VPC with public/private subnets
- Application Load Balancer
- EC2 web servers
- RDS PostgreSQL database
- S3 for static assets

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

## Cost
~$100/month for dev environment

## Access
After deployment:
```bash
terraform output alb_url
```

## Cleanup
```bash
terraform destroy
```
