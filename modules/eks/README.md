# AWS EKS Cluster Terraform Module

This module creates a production-ready Amazon EKS cluster with managed node groups, Fargate profiles, IRSA support, and essential add-ons.

## Features

- EKS cluster with configurable Kubernetes version
- Managed node groups with auto-scaling
- Multiple node groups support with different configurations
- IAM Roles for Service Accounts (IRSA) via OIDC provider
- Fargate profiles for serverless containers
- EKS add-ons (VPC CNI, CoreDNS, kube-proxy)
- CloudWatch logging for control plane
- Encryption at rest for secrets
- Security groups with proper ingress/egress rules
- SSM access for node management
- Support for both public and private API endpoints

## Usage

### Basic Example

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_encryption_key_arn = aws_kms_key.eks.arn

  node_groups = {
    general = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      ami_type       = "AL2_x86_64"
    }
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

### Advanced Example with Multiple Node Groups

```hcl
# KMS key for cluster encryption
resource "aws_kms_key" "eks" {
  description             = "EKS cluster encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = "production-eks"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # API endpoint access
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["10.0.0.0/8", "172.16.0.0/12"]

  # Encryption
  cluster_encryption_key_arn = aws_kms_key.eks.arn

  # Control plane logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_retention_days = 30

  # Enable IRSA
  enable_irsa = true

  # Multiple node groups for different workloads
  node_groups = {
    # General purpose nodes
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

    # Compute optimized nodes
    compute = {
      desired_size   = 2
      max_size       = 10
      min_size       = 1
      instance_types = ["c5.2xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      ami_type       = "AL2_x86_64"
      
      labels = {
        role     = "compute"
        workload = "cpu-intensive"
      }
      
      taints = [
        {
          key    = "workload"
          value  = "compute"
          effect = "NO_SCHEDULE"
        }
      ]
    }

    # Spot instances for cost optimization
    spot = {
      desired_size   = 2
      max_size       = 8
      min_size       = 0
      instance_types = ["t3.large", "t3a.large", "t2.large"]
      capacity_type  = "SPOT"
      disk_size      = 50
      ami_type       = "AL2_x86_64"
      
      labels = {
        role         = "spot"
        "node.kubernetes.io/lifecycle" = "spot"
      }
      
      taints = [
        {
          key    = "spotInstance"
          value  = "true"
          effect = "PREFER_NO_SCHEDULE"
        }
      ]
    }

    # GPU nodes for ML workloads
    gpu = {
      desired_size   = 1
      max_size       = 4
      min_size       = 0
      instance_types = ["g4dn.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      ami_type       = "AL2_x86_64_GPU"
      
      labels = {
        role     = "gpu"
        workload = "ml"
      }
      
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  # EKS Add-ons
  cluster_addons = {
    vpc-cni = {
      addon_version = "v1.15.0-eksbuild.2"
    }
    coredns = {
      addon_version = "v1.10.1-eksbuild.4"
    }
    kube-proxy = {
      addon_version = "v1.28.1-eksbuild.1"
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.24.0-eksbuild.1"
      service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    }
  }

  tags = {
    Environment = "production"
    Team        = "platform"
    Terraform   = "true"
  }
}

# Configure kubectl
resource "null_resource" "kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_id} --region ${var.aws_region}"
  }
}
```

### Example with Fargate Profiles

```hcl
module "eks_with_fargate" {
  source = "./modules/eks"

  cluster_name    = "fargate-eks"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_encryption_key_arn = aws_kms_key.eks.arn

  # Managed node group for system workloads
  node_groups = {
    system = {
      desired_size   = 2
      max_size       = 3
      min_size       = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      ami_type       = "AL2_x86_64"
      
      labels = {
        role = "system"
      }
    }
  }

  # Fargate profiles for application workloads
  fargate_profiles = {
    applications = {
      subnet_ids = module.vpc.private_subnet_ids
      selectors = [
        {
          namespace = "applications"
        }
      ]
    }
    
    backend = {
      subnet_ids = module.vpc.private_subnet_ids
      selectors = [
        {
          namespace = "backend"
          labels = {
            fargate = "true"
          }
        }
      ]
    }
  }

  tags = {
    Environment = "production"
  }
}
```

### Private Cluster Example

```hcl
module "private_eks" {
  source = "./modules/eks"

  cluster_name    = "private-eks"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Private cluster configuration
  endpoint_private_access = true
  endpoint_public_access  = false

  cluster_encryption_key_arn = aws_kms_key.eks.arn

  node_groups = {
    private = {
      desired_size   = 3
      max_size       = 5
      min_size       = 2
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      ami_type       = "AL2_x86_64"
      
      # Enable SSH access via SSM
      key_name = aws_key_pair.eks_nodes.key_name
    }
  }

  # Enable SSM for secure access
  enable_ssm = true

  tags = {
    Environment = "production"
    Access      = "private"
  }
}
```

## Post-Deployment Configuration

After creating the cluster, you'll need to:

### 1. Update kubeconfig

```bash
aws eks update-kubeconfig --name my-eks-cluster --region us-east-1
```

### 2. Verify cluster access

```bash
kubectl get nodes
kubectl get pods -A
```

### 3. Create IAM role for service account (example for EBS CSI driver)

```hcl
data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "eks-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0
- Kubernetes Provider >= 2.0 (for post-deployment configuration)

## Important Notes

1. **KMS Key**: You must provide a KMS key for cluster encryption
2. **Subnets**: Subnet IDs must be in at least 2 different availability zones
3. **Node IAM**: Node IAM role is shared across all node groups
4. **Updates**: Node group updates may cause temporary disruption
5. **Fargate**: Fargate profiles require CoreDNS to run on Fargate (patch required)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the EKS cluster | string | n/a | yes |
| cluster_version | Kubernetes version | string | "1.28" | no |
| vpc_id | VPC ID | string | n/a | yes |
| subnet_ids | List of subnet IDs | list(string) | n/a | yes |
| cluster_encryption_key_arn | KMS key ARN | string | n/a | yes |
| endpoint_private_access | Enable private endpoint | bool | true | no |
| endpoint_public_access | Enable public endpoint | bool | true | no |
| node_groups | Map of node group configs | map(object) | {} | no |
| cluster_addons | Map of EKS addons | map(object) | vpc-cni, coredns, kube-proxy | no |
| fargate_profiles | Map of Fargate profiles | map(object) | {} | no |
| enable_irsa | Enable IRSA | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | Kubernetes API endpoint |
| cluster_certificate_authority_data | CA certificate |
| oidc_provider_arn | OIDC provider ARN |
| node_iam_role_name | Node IAM role name |
| cluster_security_group_id | Cluster security group ID |
