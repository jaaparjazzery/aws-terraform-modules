# docs/ARCHITECTURE.md
# Architecture Documentation

## Overview

This document describes the architecture and design decisions for the AWS Terraform Modules collection.

## Design Principles

### 1. Modularity
- Each module is self-contained and independent
- Modules can be composed together
- No tight coupling between modules
- Clear input/output interfaces

### 2. Security by Default
- Encryption enabled by default
- Private subnets for sensitive resources
- Least privilege IAM policies
- No hardcoded credentials
- Security scanning in CI/CD

### 3. Flexibility
- Sensible defaults with override capability
- Support for multiple configurations
- Environment-agnostic design
- Region-agnostic where possible

### 4. Maintainability
- Clear code structure
- Comprehensive documentation
- Automated testing
- Version control

## Module Architecture

### VPC Module

```
┌─────────────────────────────────────────┐
│           VPC (10.0.0.0/16)             │
│                                         │
│  ┌────────────┐      ┌───────────────┐ │
│  │  Public    │      │   Private     │ │
│  │  Subnets   │      │   Subnets     │ │
│  │            │      │               │ │
│  │ ┌────────┐ │      │ ┌───────────┐│ │
│  │ │  IGW   │ │      │ │    NAT    ││ │
│  │ └───┬────┘ │      │ │  Gateway  ││ │
│  │     │      │      │ └─────┬─────┘│ │
│  │     │      │      │       │      │ │
│  └─────┼──────┘      └───────┼──────┘ │
│        │                     │        │
│        └─────────┬───────────┘        │
│                  │                    │
└──────────────────┼────────────────────┘
                   │
               Internet
```

**Components:**
- VPC with customizable CIDR
- Public subnets (map public IPs)
- Private subnets (no public IPs)
- Internet Gateway (IGW)
- NAT Gateways (one per AZ)
- Route tables and associations

**Design Decisions:**
- One NAT Gateway per AZ for high availability
- Public subnets in separate AZs
- Private subnets for databases and applications
- DNS hostnames enabled by default

### S3 Bucket Module

```
┌─────────────────────────────────────┐
│         S3 Bucket                   │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Server-Side Encryption      │  │
│  │  (AES256 or KMS)             │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Versioning                  │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Lifecycle Rules             │  │
│  │  - Transition to IA          │  │
│  │  - Transition to Glacier     │  │
│  │  - Expiration                │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Public Access Block         │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Components:**
- Bucket with unique naming
- Encryption configuration
- Versioning control
- Lifecycle policies
- Public access blocking
- Access logging (optional)
- CORS configuration (optional)

**Design Decisions:**
- Encryption enabled by default
- Versioning enabled by default
- Public access blocked by default
- Lifecycle rules for cost optimization

### EC2 Instance Module

```
┌─────────────────────────────────────┐
│       EC2 Instance                  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  AMI (Auto-selected)         │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Root Volume (EBS)           │  │
│  │  - Encrypted                 │  │
│  │  - Type: gp3                 │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Additional EBS Volumes      │  │
│  │  (Optional)                  │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  IAM Instance Profile        │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  User Data Script            │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Security Groups             │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Components:**
- Instance with auto AMI lookup
- Encrypted EBS volumes
- IAM instance profile
- User data for initialization
- Security group associations
- Optional Elastic IP

**Design Decisions:**
- Latest AMI automatically selected
- IMDSv2 required for security
- Root volume encrypted by default
- gp3 volumes for better performance
- IAM roles instead of access keys

### RDS Module

```
┌──────────────────────────────────────────┐
│          RDS Database                    │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Primary Instance                  │ │
│  │  - Multi-AZ (Optional)             │ │
│  │  - Encrypted Storage               │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Read Replicas (Optional)          │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Automated Backups                 │ │
│  │  - Retention Period                │ │
│  │  - Backup Window                   │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Parameter Group                   │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Subnet Group                      │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Performance Insights              │ │
│  └────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

**Components:**
- RDS instance (various engines)
- Multi-AZ deployment option
- Read replicas
- Automated backups
- Parameter groups
- Subnet groups
- Enhanced monitoring
- Performance Insights

**Design Decisions:**
- Storage encrypted by default
- Automated backups enabled
- Multi-AZ for production
- Custom parameter groups
- CloudWatch Logs integration

## Component Interactions

### Example: Three-Tier Web Application

```
                    Internet
                       │
                       ▼
        ┌──────────────────────────┐
        │   Application Load       │
        │   Balancer (Public)      │
        └──────────┬───────────────┘
                   │
        ┌──────────┴───────────┐
        │                      │
        ▼                      ▼
┌───────────────┐      ┌───────────────┐
│  Web Tier     │      │  Web Tier     │
│  (EC2)        │      │  (EC2)        │
│  Private      │      │  Private      │
│  Subnet       │      │  Subnet       │
└───────┬───────┘      └───────┬───────┘
        │                      │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │   RDS Database       │
        │   (Multi-AZ)         │
        │   Private Subnet     │
        └──────────────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │   S3 Bucket          │
        │   (Static Assets)    │
        └──────────────────────┘
```

## Data Flow

### 1. User Request Flow
```
User → ALB → EC2 (Web) → RDS (Database) → S3 (Assets)
```

### 2. Deployment Flow
```
Terraform → AWS API → Resources Created → State Updated
```

### 3. CI/CD Flow
```
Git Push → GitHub Actions → Tests → Security Scans → Deploy
```

## Security Architecture

### Defense in Depth

```
Layer 1: Network (VPC, Security Groups, NACLs)
Layer 2: IAM (Roles, Policies, IRSA)
Layer 3: Encryption (KMS, TLS/SSL)
Layer 4: Monitoring (CloudWatch, Flow Logs)
Layer 5: Compliance (Security Scans, Audits)
```

### Security Zones

```
┌─────────────────────────────────────┐
│         Public Zone                 │
│  - ALB                              │
│  - NAT Gateway                      │
│  - Bastion (optional)               │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│       Application Zone              │
│  - EC2 Instances                    │
│  - EKS Nodes                        │
│  - Private Subnets                  │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│         Data Zone                   │
│  - RDS Databases                    │
│  - ElastiCache                      │
│  - Private Subnets                  │
│  - No Internet Access               │
└─────────────────────────────────────┘
```

## Scalability Patterns

### Horizontal Scaling
- Auto Scaling Groups for EC2
- EKS Node Groups
- RDS Read Replicas
- ALB Target Groups

### Vertical Scaling
- Instance type changes
- RDS instance classes
- EBS volume sizes

## High Availability

### Multi-AZ Strategy
```
Region: us-east-1
├── AZ-A (us-east-1a)
│   ├── Public Subnet
│   ├── Private Subnet
│   ├── NAT Gateway
│   └── Resources
├── AZ-B (us-east-1b)
│   ├── Public Subnet
│   ├── Private Subnet
│   ├── NAT Gateway
│   └── Resources
└── AZ-C (us-east-1c)
    ├── Public Subnet
    ├── Private Subnet
    ├── NAT Gateway
    └── Resources
```

## Best Practices Applied

1. **Infrastructure as Code**
   - All infrastructure defined in Terraform
   - Version controlled
   - Repeatable deployments

2. **Immutable Infrastructure**
   - Replace rather than update
   - Use launch templates
   - Blue/green deployments

3. **Least Privilege**
   - Minimal IAM permissions
   - Security group restrictions
   - Network segmentation

4. **Automation**
   - CI/CD pipelines
   - Automated testing
   - Drift detection

5. **Monitoring & Logging**
   - CloudWatch integration
   - Centralized logging
   - Alerting on anomalies

## Future Enhancements

1. **Multi-Region Support**
   - Cross-region replication
   - Global load balancing
   - Disaster recovery

2. **Service Mesh**
   - Istio/Linkerd integration
   - Advanced traffic management
   - Observability

3. **GitOps**
   - ArgoCD/Flux integration
   - Automated synchronization
   - Declarative deployments

4. **Cost Optimization**
   - Spot instance integration
   - Reserved instance management
   - Cost allocation tags
