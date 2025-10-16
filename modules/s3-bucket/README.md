# AWS S3 Bucket Terraform Module

This module creates a secure S3 bucket with configurable encryption, versioning, lifecycle policies, and access controls.

## Features

- Server-side encryption (AES256 or KMS)
- Versioning support
- Public access blocking by default
- Lifecycle rules for object transitions and expiration
- Access logging
- CORS configuration
- Comprehensive tagging

## Usage

### Basic Example

```hcl
module "my_bucket" {
  source = "./modules/s3-bucket"

  bucket_name        = "my-app-bucket"
  versioning_enabled = true
  
  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
```

### Advanced Example with Lifecycle Rules

```hcl
module "archive_bucket" {
  source = "./modules/s3-bucket"

  bucket_name        = "my-archive-bucket"
  versioning_enabled = true
  sse_algorithm      = "aws:kms"
  kms_master_key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  lifecycle_rules = [
    {
      id      = "archive-old-objects"
      enabled = true
      prefix  = "logs/"
      
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
  
  logging_bucket = "my-log-bucket"
  logging_prefix = "s3-access-logs/"
  
  tags = {
    Environment = "production"
    Purpose     = "archive"
  }
}
```

### With CORS Configuration

```hcl
module "public_assets" {
  source = "./modules/s3-bucket"

  bucket_name = "my-public-assets"
  
  # Allow public read access for website assets
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://example.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]
  
  tags = {
    Environment = "production"
    Purpose     = "cdn-assets"
  }
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the S3 bucket | string | n/a | yes |
| force_destroy | Allow bucket to be destroyed even if it contains objects | bool | false | no |
| versioning_enabled | Enable versioning for the bucket | bool | true | no |
| sse_algorithm | Server-side encryption algorithm (AES256 or aws:kms) | string | "AES256" | no |
| kms_master_key_id | KMS key ID for encryption | string | null | no |
| block_public_acls | Block public ACLs | bool | true | no |
| block_public_policy | Block public bucket policies | bool | true | no |
| ignore_public_acls | Ignore public ACLs | bool | true | no |
| restrict_public_buckets | Restrict public bucket policies | bool | true | no |
| lifecycle_rules | List of lifecycle rules | list(object) | [] | no |
| logging_bucket | Target bucket for access logs | string | null | no |
| logging_prefix | Prefix for access logs | string | "logs/" | no |
| cors_rules | CORS rules configuration | list(object) | [] | no |
| tags | Tags to apply to the bucket | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | ID of the S3 bucket |
| bucket_arn | ARN of the S3 bucket |
| bucket_domain_name | Domain name of the S3 bucket |
| bucket_regional_domain_name | Regional domain name of the S3 bucket |
| bucket_region | Region of the S3 bucket |
