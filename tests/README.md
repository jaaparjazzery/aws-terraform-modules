# AWS Infrastructure Testing with Terratest

This repository contains automated integration tests for AWS infrastructure provisioned with Terraform using the Terratest framework.

## Overview

These tests validate the creation and configuration of various AWS resources including:
- VPC (Virtual Private Cloud)
- RDS (Relational Database Service)
- S3 (Simple Storage Service)
- EKS (Elastic Kubernetes Service)

## Prerequisites

### Required Tools

1. **Go** (version 1.21 or higher)
   ```bash
   # Verify installation
   go version
   ```

2. **Terraform** (version 1.0 or higher)
   ```bash
   # Verify installation
   terraform version
   ```

3. **AWS CLI** (configured with appropriate credentials)
   ```bash
   # Verify installation
   aws --version
   
   # Configure AWS credentials
   aws configure
   ```

4. **AWS Credentials**
   - Ensure you have AWS credentials configured with sufficient permissions
   - Tests will use credentials from `~/.aws/credentials` or environment variables

### AWS Permissions

Your AWS user/role needs permissions for:
- EC2 (VPC, Subnets, Internet Gateway, NAT Gateway)
- RDS (DB Instances, DB Subnet Groups, DB Security Groups)
- S3 (Bucket creation, configuration, tagging)
- EKS (Cluster creation, Node Groups, IAM roles)
- IAM (Role creation for EKS)

## Project Structure

```
.
├── go.mod                  # Go module dependencies
├── README.md              # This file
├── vpc_test.go            # VPC infrastructure tests
├── rds_test.go            # RDS database tests
├── s3_test.go             # S3 bucket tests
├── eks_test.go            # EKS cluster tests
├── test_helpers.go        # Shared helper functions
└── terraform/             # Terraform configurations
    ├── vpc/
    ├── rds/
    ├── s3/
    └── eks/
```

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd aws-terraform-tests
   ```

2. Initialize Go modules:
   ```bash
   go mod download
   ```

3. Verify dependencies:
   ```bash
   go mod verify
   ```

## Running Tests

### Run All Tests

```bash
go test -v -timeout 30m
```

### Run Specific Test Suite

```bash
# VPC tests only
go test -v -timeout 30m -run TestVPC

# RDS tests only
go test -v -timeout 30m -run TestRDS

# S3 tests only
go test -v -timeout 30m -run TestS3

# EKS tests only
go test -v -timeout 30m -run TestEKS
```

### Run Individual Test

```bash
go test -v -timeout 30m -run TestVPCCreation
```

### Run Tests in Parallel

Tests are configured to run in parallel by default using `t.Parallel()`:

```bash
go test -v -timeout 60m -parallel 4
```

## Test Details

### VPC Tests (`vpc_test.go`)

- **TestVPCCreation**: Validates VPC creation with public/private subnets, Internet Gateway, and NAT Gateway
- **TestVPCWithCustomCIDR**: Tests VPC with custom CIDR block
- **TestVPCTags**: Verifies proper tagging of VPC resources

### RDS Tests (`rds_test.go`)

- **TestRDSInstanceCreation**: Validates RDS instance creation with specified configuration
- **TestRDSWithMultiAZ**: Tests Multi-AZ deployment
- **TestRDSWithBackupRetention**: Verifies backup configuration
- **TestRDSEncryption**: Tests encryption at rest

### S3 Tests (`s3_test.go`)

- **TestS3BucketCreation**: Validates S3 bucket creation
- **TestS3BucketVersioning**: Tests bucket versioning configuration
- **TestS3BucketEncryption**: Verifies server-side encryption
- **TestS3BucketLifecyclePolicy**: Tests lifecycle rules
- **TestS3BucketPublicAccessBlock**: Validates public access block settings
- **TestS3BucketTags**: Tests bucket tagging

### EKS Tests (`eks_test.go`)

- **TestEKSClusterCreation**: Validates EKS cluster creation
- **TestEKSNodeGroup**: Tests node group configuration
- **TestEKSClusterLogging**: Verifies control plane logging
- **TestEKSClusterEncryption**: Tests secrets encryption
- **TestEKSClusterTags**: Validates cluster tagging
- **TestEKSPublicAndPrivateAccess**: Tests endpoint access configuration

## Important Notes

### Timeouts

Tests have extended timeouts (30-60 minutes) because AWS resources take time to provision:
- VPC resources: 5-10 minutes
- RDS instances: 10-20 minutes
- S3 buckets: 1-2 minutes
- EKS clusters: 15-30 minutes

### Cleanup

Each test includes a `defer terraform.Destroy()` to clean up resources after testing. However, if a test fails unexpectedly:

```bash
# Navigate to the terraform directory
cd terraform/<resource-type>

# Manually destroy resources
terraform destroy -auto-approve
```

### Costs

**Warning**: Running these tests will incur AWS charges. Resources are automatically destroyed after each test, but ensure:
- Tests complete successfully
- No orphaned resources remain
- Review AWS billing regularly

Estimated costs per test run:
- VPC: ~$0.10
- RDS: ~$0.50-1.00
- S3: ~$0.01
- EKS: ~$2.00-3.00

### Parallel Testing

Tests use `t.Parallel()` to run concurrently, which:
- Reduces total execution time
- May increase AWS costs temporarily
- Requires sufficient AWS service limits

## Environment Variables

Optional environment variables for test configuration:

```bash
# AWS Region (default: us-east-1)
export AWS_DEFAULT_REGION=us-west-2

# Terratest logging level
export TERRATEST_LOG_LEVEL=debug

# Disable parallel execution
export GOMAXPROCS=1
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   ```
   Error: error configuring Terraform AWS Provider: no valid credential sources
   ```
   Solution: Configure AWS credentials using `aws configure`

2. **Timeout Errors**
   ```
   Test timed out after 30m
   ```
   Solution: Increase timeout: `go test -timeout 60m`

3. **Resource Quota Exceeded**
   ```
   Error: VPC limit exceeded
   ```
   Solution: Request limit increase in AWS Service Quotas console

4. **Orphaned Resources**
   ```
   Error: Resource already exists
   ```
   Solution: Manually clean up resources in AWS console or use Terraform destroy

### Debug Mode

Run tests with verbose output:

```bash
TF_LOG=DEBUG go test -v -timeout 30m -run TestVPCCreation
```

## Best Practices

1. **Run tests in isolated AWS account/environment**
2. **Use unique resource names** (tests use timestamps)
3. **Monitor AWS costs** during testing
4. **Review test results** before merging changes
5. **Clean up manually** if tests fail unexpectedly
6. **Use proper IAM permissions** (least privilege)
7. **Tag all resources** for cost tracking

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Terraform Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - uses: hashicorp/setup-terraform@v2
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Run Tests
        run: go test -v -timeout 60m
```

## Contributing

1. Write tests for new infrastructure components
2. Follow existing test patterns
3. Include proper cleanup in `defer` statements
4. Document any special requirements
5. Test locally before submitting PR

## Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [AWS SDK for Go](https://aws.github.io/aws-sdk-go-v2/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

MIT License - See LICENSE file for details

## Support

For issues or questions:
- Open an issue in the repository
- Contact the DevOps team
- Review AWS and Terratest documentation
