# AWS ECR Repository Module

Terraform module for creating and managing Amazon Elastic Container Registry (ECR) repositories with advanced features including lifecycle policies, image scanning, replication, and cross-account access.

## Features

- **Image Scanning**: Automatic and manual vulnerability scanning
- **Lifecycle Policies**: Automated image cleanup and retention
- **Encryption**: Server-side encryption with AWS-managed or customer-managed KMS keys
- **Replication**: Cross-region and cross-account replication
- **Access Control**: Repository policies for fine-grained permissions
- **Image Immutability**: Tag immutability for production images
- **Scan on Push**: Automatic vulnerability scanning on image push
- **Pull Through Cache**: Cache images from public registries
- **Force Delete**: Safe deletion with automatic image cleanup
- **CloudWatch Integration**: Metrics and monitoring
- **Tags**: Comprehensive resource tagging

## Usage

### Basic ECR Repository

```hcl
module "basic_repo" {
  source = "./modules/ecr"

  repository_name = "my-app"
  
  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
```

### Repository with Image Scanning

```hcl
module "scanned_repo" {
  source = "./modules/ecr"

  repository_name = "secure-app"
  
  # Enable automatic scanning on push
  scan_on_push = true
  
  # Image tag immutability
  image_tag_mutability = "IMMUTABLE"
  
  tags = {
    Environment = "production"
    Security    = "high"
  }
}
```

### Repository with Lifecycle Policy

```hcl
module "lifecycle_repo" {
  source = "./modules/ecr"

  repository_name = "web-service"
  
  # Lifecycle policy to clean up old images
  lifecycle_policy = {
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Keep last 3 dev images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev"]
          countType     = "imageCountMoreThan"
          countNumber   = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Repository with Cross-Account Access

```hcl
module "shared_repo" {
  source = "./modules/ecr"

  repository_name = "shared-base-images"
  
  # Repository policy for cross-account access
  repository_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::123456789012:root",
            "arn:aws:iam::234567890123:root"
          ]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  }
  
  tags = {
    Shared = "true"
  }
}
```

### Repository with Encryption

```hcl
module "encrypted_repo" {
  source = "./modules/ecr"

  repository_name = "sensitive-app"
  
  # KMS encryption
  encryption_configuration = {
    encryption_type = "KMS"
    kms_key_arn     = aws_kms_key.ecr.arn
  }
  
  # Image tag immutability
  image_tag_mutability = "IMMUTABLE"
  
  # Scan on push
  scan_on_push = true
  
  tags = {
    Environment = "production"
    Compliance  = "pci-dss"
  }
}
```

### Repository with Replication

```hcl
module "replicated_repo" {
  source = "./modules/ecr"

  repository_name = "global-app"
  
  # Enable replication
  replication_configuration = {
    rules = [
      {
        destinations = [
          {
            region      = "us-west-2"
            registry_id = data.aws_caller_identity.current.account_id
          },
          {
            region      = "eu-west-1"
            registry_id = data.aws_caller_identity.current.account_id
          }
        ]
        
        repository_filters = [
          {
            filter      = "global-app"
            filter_type = "PREFIX_MATCH"
          }
        ]
      },
      {
        # Cross-account replication
        destinations = [
          {
            region      = "us-east-1"
            registry_id = "987654321098"
          }
        ]
      }
    ]
  }
  
  tags = {
    Environment = "production"
    Scope       = "global"
  }
}
```

### Advanced Production Repository

```hcl
module "production_repo" {
  source = "./modules/ecr"

  repository_name      = "production-service"
  image_tag_mutability = "IMMUTABLE"
  
  # Enhanced security scanning
  scan_on_push = true
  
  scanning_configuration = {
    scan_type = "ENHANCED"  # Uses Amazon Inspector
    rules = [
      {
        scan_frequency = "CONTINUOUS_SCAN"
        filter = {
          filter      = "prod-*"
          filter_type = "WILDCARD"
        }
      }
    ]
  }
  
  # KMS encryption
  encryption_configuration = {
    encryption_type = "KMS"
    kms_key_arn     = aws_kms_key.ecr.arn
  }
  
  # Comprehensive lifecycle policy
  lifecycle_policy = {
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-v"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 staging images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["staging-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Remove dev images older than 14 days"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 14
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 4
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  }
  
  # Repository policy
  repository_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowEKSPull"
        Effect = "Allow"
        Principal = {
          AWS = module.eks.node_role_arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowCICD"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.cicd.arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  }
  
  # Cross-region replication
  replication_configuration = {
    rules = [
      {
        destinations = [
          {
            region      = "us-west-2"
            registry_id = data.aws_caller_identity.current.account_id
          },
          {
            region      = "eu-central-1"
            registry_id = data.aws_caller_identity.current.account_id
          }
        ]
      }
    ]
  }
  
  # Force delete - allows Terraform to delete repo with images
  force_delete = false
  
  tags = {
    Environment      = "production"
    ManagedBy        = "terraform"
    CriticalityLevel = "high"
    Compliance       = "soc2"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repository_name | Name of the ECR repository | `string` | n/a | yes |
| image_tag_mutability | Image tag mutability (MUTABLE or IMMUTABLE) | `string` | `"MUTABLE"` | no |
| scan_on_push | Enable automatic scanning on image push | `bool` | `false` | no |
| scanning_configuration | Advanced scanning configuration | `object` | `null` | no |
| encryption_configuration | Encryption configuration | `object` | `null` | no |
| lifecycle_policy | Lifecycle policy for image retention | `object` | `null` | no |
| repository_policy | IAM policy for repository access | `object` | `null` | no |
| replication_configuration | Replication configuration | `object` | `null` | no |
| force_delete | Allow deletion with images present | `bool` | `false` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_arn | ARN of the ECR repository |
| repository_name | Name of the ECR repository |
| repository_url | URL of the ECR repository |
| repository_registry_id | Registry ID of the repository |
| repository_repository_url | Full repository URL |

## Examples

### Multi-Environment Repository Setup

```hcl
module "app_repos" {
  source = "./modules/ecr"
  
  for_each = toset(["frontend", "backend", "worker"])

  repository_name      = "${each.key}-service"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  
  lifecycle_policy = {
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  }
  
  tags = {
    Environment = "production"
    Service     = each.key
  }
}
```

### Pull Through Cache Repository

```hcl
resource "aws_ecr_pull_through_cache_rule" "dockerhub" {
  ecr_repository_prefix = "dockerhub"
  upstream_registry_url = "registry-1.docker.io"
}

# Now you can pull: docker pull ${account}.dkr.ecr.${region}.amazonaws.com/dockerhub/library/nginx:latest
```

## Best Practices

### Image Management

- Use **IMMUTABLE** tags for production images
- Implement **semantic versioning** for image tags
- Tag images with **git commit SHA** for traceability
- Use **multi-stage builds** to reduce image size
- Store **base images** in separate repositories
- Create **dedicated repositories** per service

### Security

- Enable **scan on push** for all repositories
- Use **enhanced scanning** for critical applications
- Enable **KMS encryption** for sensitive workloads
- Implement **least privilege** repository policies
- Regularly review **scan findings**
- Use **image signing** for verification
- Enable **tag immutability** for production images

### Cost Optimization

- Implement **lifecycle policies** to remove old images
- Remove **untagged images** regularly
- Use **compression** in Docker images
- Share **base images** across teams
- Monitor **storage usage** with CloudWatch
- Consider **S3 Glacier** for long-term image archives

### High Availability

- Enable **cross-region replication** for critical images
- Use **pull through cache** for public images
- Implement **repository policies** for disaster recovery
- Maintain **image backups** in multiple regions

### CI/CD Integration

- Use **service roles** for ECS/EKS pulls
- Create **dedicated IAM users** for CI/CD pipelines
- Implement **automated scanning** in pipelines
- Use **cache layers** to speed up builds
- Tag images with **build metadata**

## Cost Considerations

### Pricing Components

**Storage:**
- $0.10 per GB per month

**Data Transfer:**
- IN: Free
- OUT to Internet: $0.09 per GB (after free tier)
- OUT to AWS services in same region: Free
- OUT to other AWS regions: $0.02 per GB

**Enhanced Scanning:**
- $0.09 per image scan (continuous scanning)
- First scan free for each image
- Re-scans triggered by new CVE data

### Example Costs

| Usage Pattern | Storage | Scans | Monthly Cost |
|---------------|---------|-------|--------------|
| Small app (10 images, 1GB each) | 10 GB | Basic | ~$1 |
| Medium app (50 images, 2GB each) | 100 GB | Basic | ~$10 |
| Large app (200 images, 3GB each) | 600 GB | Enhanced | ~$78 |
| Enterprise (1000 images, 5GB) | 5 TB | Enhanced | ~$590 |

**Cost Optimization Tips:**
- Delete old and unused images
- Optimize image sizes
- Use lifecycle policies
- Share base images
- Monitor storage growth

### Storage Calculation

```
Monthly Storage Cost = (Total GB) × $0.10
Data Transfer Cost = (GB transferred) × $0.09 (to Internet)
Enhanced Scan Cost = (Number of images scanned) × $0.09
```

## Additional Resources

- [ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
- [ECR Best Practices](https://docs.aws.amazon.com/AmazonECR/latest/userguide/best-practices.html)
- [ECR Pricing](https://aws.amazon.com/ecr/pricing/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Image Scanning Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html)

## License

This module is licensed under the MIT License.