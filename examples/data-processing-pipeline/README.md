# Data Processing Pipeline

Scalable data processing infrastructure with auto-scaling.

## Architecture
- Multi-stage S3 buckets (raw, processed)
- Coordinator EC2 instance
- RDS for metadata
- Auto-scaling processors

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform apply
```

## Usage

Upload data:
```bash
aws s3 cp mydata.csv s3://$(terraform output -raw raw_data_bucket)/incoming/
```

## Cost
~$200-300/month

## Cleanup
```bash
terraform destroy
```
