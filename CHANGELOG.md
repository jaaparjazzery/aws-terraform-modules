# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Pre-commit hooks configuration
- GitHub Actions CI/CD workflows
- Automated security scanning
- Cost estimation workflow
- Drift detection automation
- Comprehensive testing suite

### Changed
- Improved documentation structure
- Enhanced security defaults

### Fixed
- Various bug fixes and improvements

## [1.0.0] - 2024-01-15

### Added
- Initial release of AWS Terraform Modules
- VPC Module with Multi-AZ support
- S3 Bucket Module with encryption and lifecycle policies
- EC2 Instance Module with IMDSv2 enforcement
- RDS Database Module with Multi-AZ and read replicas
- Application Load Balancer Module with advanced routing
- EKS Cluster Module with IRSA and managed node groups
- Three complete examples:
  - Simple Web Application
  - Microservices Platform on EKS
  - Data Processing Pipeline
- Comprehensive documentation for all modules
- Security best practices implementation
- Cost optimization guidelines

### Security
- Encryption at rest enabled by default
- KMS key support across all modules
- Private subnet defaults for sensitive resources
- Security group least privilege implementation
- No hardcoded credentials
- IMDSv2 enforcement on EC2 instances

## Release Process

### Version Numbering

We follow semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes that require migration
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes and minor improvements

### Creating a Release

1. Update CHANGELOG.md with version and date
2. Commit changes: `git commit -m "chore: prepare release v1.0.0"`
3. Create tag: `git tag -a v1.0.0 -m "Release version 1.0.0"`
4. Push changes: `git push origin main --tags`
5. GitHub Actions will automatically create the release

### Migration Guides

For breaking changes, see the migration guides in the `docs/migrations/` directory.

---

## [Planned]

### Version 2.0.0 (Future)

**Breaking Changes:**
- Terraform 1.7+ required
- AWS Provider 5.30+ required
- Module path restructuring

**New Features:**
- Lambda Function Module
- DynamoDB Table Module
- CloudFront Distribution Module
- API Gateway Module
- ECR Repository Module
- Step Functions Module
- SNS/SQS Messaging Module
- ElastiCache Module
- Route53 DNS Module
- WAF Security Module

**Improvements:**
- Enhanced testing coverage
- Performance optimizations
- Additional security controls
- Multi-region support
- Disaster recovery features

---

## Contributor Recognition

We appreciate all contributors! Contributors are listed in each release.

### How to Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

---

[Unreleased]: https://github.com/jaaparjazzery/aws-terraform-modules/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/jaaparjazzery/aws-terraform-modules/releases/tag/v1.0.0

---

# Terratest Example

File: `test/vpc_test.go`

```go
package test

import (
    "fmt"
    "strings"
    "testing"

    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/gruntwork-io/terratest/modules/random"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

// TestVPCModule tests the VPC module
func TestVPCModule(t *testing.T) {
    t.Parallel()

    // Pick a random AWS region
    awsRegion := aws.GetRandomStableRegion(t, nil, nil)
    
    // Generate unique VPC name
    uniqueId := random.UniqueId()
    vpcName := fmt.Sprintf("test-vpc-%s", strings.ToLower(uniqueId))

    terraformOptions := &terraform.Options{
        // Path to the Terraform code
        TerraformDir: "../modules/vpc",

        // Variables to pass to Terraform
        Vars: map[string]interface{}{
            "vpc_name":           vpcName,
            "vpc_cidr":           "10.0.0.0/16",
            "availability_zones": []string{
                fmt.Sprintf("%sa", awsRegion),
                fmt.Sprintf("%sb", awsRegion),
            },
            "public_subnet_cidrs":  []string{"10.0.1.0/24", "10.0.2.0/24"},
            "private_subnet_cidrs": []string{"10.0.10.0/24", "10.0.11.0/24"},
            "enable_nat_gateway":   true,
        },

        // Environment variables
        EnvVars: map[string]string{
            "AWS_DEFAULT_REGION": awsRegion,
        },

        // Disable colors in Terraform output
        NoColor: true,

        // Retry on known transient errors
        MaxRetries:         3,
        TimeBetweenRetries: 5 * time.Second,
    }

    // Clean up resources at the end of the test
    defer terraform.Destroy(t, terraformOptions)

    // Initialize and apply Terraform
    terraform.InitAndApply(t, terraformOptions)

    // Validate outputs
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId, "VPC ID should not be empty")
    
    publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
    assert.Equal(t, 2, len(publicSubnetIds), "Should have 2 public subnets")
    
    privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
    assert.Equal(t, 2, len(privateSubnetIds), "Should have 2 private subnets")

    // Verify VPC exists in AWS
    vpc := aws.GetVpcById(t, vpcId, awsRegion)
    require.NotNil(t, vpc, "VPC should exist")
    assert.Equal(t, "10.0.0.0/16", *vpc.CidrBlock, "VPC CIDR should match")

    // Verify public subnets
    for _, subnetId := range publicSubnetIds {
        subnet := aws.GetSubnetById(t, subnetId, awsRegion)
        require.NotNil(t, subnet, "Public subnet should exist")
        assert.True(t, *subnet.MapPublicIpOnLaunch, "Public subnet should map public IPs")
    }

    // Verify NAT gateways exist
    natGatewayIds := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
    assert.Equal(t, 2, len(natGatewayIds), "Should have 2 NAT gateways")
    
    for _, natGatewayId := range natGatewayIds {
        natGateway := aws.GetNatGateway(t, natGatewayId, awsRegion)
        require.NotNil(t, natGateway, "NAT gateway should exist")
        assert.Equal(t, "available", *natGateway.State, "NAT gateway should be available")
    }

    // Verify IGW exists
    igwId := terraform.Output(t, terraformOptions, "internet_gateway_id")
    igw := aws.GetInternetGateway(t, igwId, awsRegion)
    require.NotNil(t, igw, "Internet gateway should exist")
    assert.Equal(t, vpcId, *igw.Attachments[0].VpcId, "IGW should be attached to VPC")
}

// TestRDSModule tests the RDS module
func TestRDSModule(t *testing.T) {
    t.Parallel()

    awsRegion := aws.GetRandomStableRegion(t, nil, nil)
    uniqueId := random.UniqueId()
    dbIdentifier := fmt.Sprintf("test-db-%s", strings.ToLower(uniqueId))

    // First create VPC for RDS
    vpcOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_name":             fmt.Sprintf("test-vpc-%s", uniqueId),
            "vpc_cidr":             "10.0.0.0/16",
            "availability_zones":   []string{fmt.Sprintf("%sa", awsRegion), fmt.Sprintf("%sb", awsRegion)},
            "public_subnet_cidrs":  []string{"10.0.1.0/24", "10.0.2.0/24"},
            "private_subnet_cidrs": []string{"10.0.10.0/24", "10.0.11.0/24"},
        },
        EnvVars: map[string]string{"AWS_DEFAULT_REGION": awsRegion},
    }

    defer terraform.Destroy(t, vpcOptions)
    terraform.InitAndApply(t, vpcOptions)

    vpcId := terraform.Output(t, vpcOptions, "vpc_id")
    subnetIds := terraform.OutputList(t, vpcOptions, "private_subnet_ids")

    // Create security group
    sgId := aws.CreateSecurityGroup(t, vpcId, fmt.Sprintf("test-sg-%s", uniqueId), awsRegion)
    defer aws.DeleteSecurityGroup(t, sgId, awsRegion)

    // Create KMS key
    kmsKeyId := aws.CreateKmsKey(t, awsRegion)
    defer aws.DeleteKmsKey(t, kmsKeyId, awsRegion)

    // Test RDS module
    rdsOptions := &terraform.Options{
        TerraformDir: "../modules/rds",
        Vars: map[string]interface{}{
            "db_identifier":         dbIdentifier,
            "engine":                "postgres",
            "engine_version":        "15.4",
            "instance_class":        "db.t3.micro",
            "database_name":         "testdb",
            "master_username":       "dbadmin",
            "master_password":       "TestPassword123!",
            "subnet_ids":            subnetIds,
            "vpc_security_group_ids": []string{sgId},
            "allocated_storage":     20,
            "storage_encrypted":     true,
            "kms_key_id":           kmsKeyId,
            "skip_final_snapshot":   true,
            "deletion_protection":   false,
        },
        EnvVars: map[string]string{"AWS_DEFAULT_REGION": awsRegion},
    }

    defer terraform.Destroy(t, rdsOptions)
    terraform.InitAndApply(t, rdsOptions)

    // Validate RDS instance
    dbEndpoint := terraform.Output(t, rdsOptions, "db_instance_endpoint")
    assert.NotEmpty(t, dbEndpoint, "DB endpoint should not be empty")
    assert.Contains(t, dbEndpoint, dbIdentifier, "Endpoint should contain DB identifier")

    // Verify in AWS
    dbInstance := aws.GetRdsInstance(t, dbIdentifier, awsRegion)
    require.NotNil(t, dbInstance, "RDS instance should exist")
    assert.Equal(t, "available", *dbInstance.DBInstanceStatus, "DB should be available")
    assert.True(t, *dbInstance.StorageEncrypted, "Storage should be encrypted")
}

// TestS3BucketModule tests the S3 bucket module
func TestS3BucketModule(t *testing.T) {
    t.Parallel()

    awsRegion := aws.GetRandomStableRegion(t, nil, nil)
    uniqueId := random.UniqueId()
    bucketName := fmt.Sprintf("test-bucket-%s", strings.ToLower(uniqueId))

    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/s3-bucket",
        Vars: map[string]interface{}{
            "bucket_name":        bucketName,
            "versioning_enabled": true,
            "lifecycle_rules": []map[string]interface{}{
                {
                    "id":      "test-rule",
                    "enabled": true,
                    "transitions": []map[string]interface{}{
                        {
                            "days":          30,
                            "storage_class": "STANDARD_IA",
                        },
                    },
                },
            },
        },
        EnvVars: map[string]string{"AWS_DEFAULT_REGION": awsRegion},
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Validate outputs
    outputBucketName := terraform.Output(t, terraformOptions, "bucket_id")
    assert.Equal(t, bucketName, outputBucketName, "Bucket name should match")

    // Verify bucket exists and has correct configuration
    aws.AssertS3BucketExists(t, awsRegion, bucketName)
    
    versioning := aws.GetS3BucketVersioning(t, awsRegion, bucketName)
    assert.Equal(t, "Enabled", versioning, "Versioning should be enabled")

    // Verify encryption
    encryption := aws.GetS3BucketEncryption(t, awsRegion, bucketName)
    assert.NotNil(t, encryption, "Encryption should be configured")
}

// TestEKSModule tests the EKS module
func TestEKSModule(t *testing.T) {
    // EKS takes longer to create
    if testing.Short() {
        t.Skip("Skipping EKS test in short mode")
    }

    t.Parallel()

    awsRegion := "us-east-1" // EKS not available in all regions
    uniqueId := random.UniqueId()
    clusterName := fmt.Sprintf("test-eks-%s", strings.ToLower(uniqueId))

    // Create VPC first
    vpcOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_name":             fmt.Sprintf("test-vpc-%s", uniqueId),
            "vpc_cidr":             "10.0.0.0/16",
            "availability_zones":   []string{"us-east-1a", "us-east-1b"},
            "public_subnet_cidrs":  []string{"10.0.1.0/24", "10.0.2.0/24"},
            "private_subnet_cidrs": []string{"10.0.10.0/24", "10.0.11.0/24"},
        },
        EnvVars: map[string]string{"AWS_DEFAULT_REGION": awsRegion},
    }

    defer terraform.Destroy(t, vpcOptions)
    terraform.InitAndApply(t, vpcOptions)

    vpcId := terraform.Output(t, vpcOptions, "vpc_id")
    subnetIds := terraform.OutputList(t, vpcOptions, "private_subnet_ids")

    // Create KMS key for EKS
    kmsKeyId := aws.CreateKmsKey(t, awsRegion)
    defer aws.DeleteKmsKey(t, kmsKeyId, awsRegion)

    // Test EKS module
    eksOptions := &terraform.Options{
        TerraformDir: "../modules/eks",
        Vars: map[string]interface{}{
            "cluster_name":             clusterName,
            "cluster_version":          "1.28",
            "vpc_id":                   vpcId,
            "subnet_ids":               subnetIds,
            "cluster_encryption_key_arn": kmsKeyId,
            "node_groups": map[string]interface{}{
                "general": map[string]interface{}{
                    "desired_size":   1,
                    "max_size":       2,
                    "min_size":       1,
                    "instance_types": []string{"t3.medium"},
                    "capacity_type":  "ON_DEMAND",
                    "disk_size":      50,
                    "ami_type":       "AL2_x86_64",
                },
            },
        },
        EnvVars: map[string]string{"AWS_DEFAULT_REGION": awsRegion},
    }

    defer terraform.Destroy(t, eksOptions)
    terraform.InitAndApply(t, eksOptions)

    // Validate EKS cluster
    clusterEndpoint := terraform.Output(t, eksOptions, "cluster_endpoint")
    assert.NotEmpty(t, clusterEndpoint, "Cluster endpoint should not be empty")

    // Verify cluster in AWS
    cluster := aws.GetEksCluster(t, clusterName, awsRegion)
    require.NotNil(t, cluster, "EKS cluster should exist")
    assert.Equal(t, "ACTIVE", *cluster.Status, "Cluster should be active")
}
```

---

# Test Setup

File: `test/go.mod`

```go
module github.com/jaaparjazzery/aws-terraform-modules/test

go 1.21

require (
    github.com/gruntwork-io/terratest v0.46.8
    github.com/stretchr/testify v1.8.4
)
```

File: `test/README.md`

```markdown
# Terratest Integration Tests

## Prerequisites

- Go 1.21+
- Terraform 1.0+
- AWS credentials configured
- Sufficient AWS permissions

## Running Tests

### Run all tests
\`\`\`bash
cd test
go test -v -timeout 45m
\`\`\`

### Run specific test
\`\`\`bash
go test -v -run TestVPCModule -timeout 30m
\`\`\`

### Run tests in parallel
\`\`\`bash
go test -v -parallel 3 -timeout 60m
\`\`\`

### Skip long-running tests
\`\`\`bash
go test -v -short
\`\`\`

## Cost Warning

⚠️ These tests create real AWS resources and will incur costs!

Estimated cost per full test run: $5-10

## Cleanup

Tests automatically clean up resources, but if a test fails:

\`\`\`bash
# List test resources
aws resourcegroupstaggingapi get-resources --tag-filters Key=terratest,Values=true

# Manual cleanup if needed
terraform destroy
\`\`\`
\`\`\`
```
