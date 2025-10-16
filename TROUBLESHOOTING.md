# Troubleshooting Guide

This guide helps you resolve common issues when using these Terraform modules.

## Table of Contents

- [General Issues](#general-issues)
- [Module-Specific Issues](#module-specific-issues)
- [AWS-Related Issues](#aws-related-issues)
- [Terraform State Issues](#terraform-state-issues)
- [Performance Issues](#performance-issues)
- [Debugging Techniques](#debugging-techniques)

---

## General Issues

### Issue: Terraform initialization fails

**Symptoms:**
```
Error: Failed to query available provider packages
```

**Solutions:**

1. **Check Terraform version:**
   ```bash
   terraform version
   # Should be >= 1.0
   ```

2. **Clear Terraform cache:**
   ```bash
   rm -rf .terraform .terraform.lock.hcl
   terraform init
   ```

3. **Update provider versions:**
   ```bash
   terraform init -upgrade
   ```

4. **Check network connectivity:**
   ```bash
   curl -I https://registry.terraform.io
   ```

### Issue: Provider authentication fails

**Symptoms:**
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**Solutions:**

1. **Verify AWS credentials:**
   ```bash
   aws sts get-caller-identity
   ```

2. **Set credentials explicitly:**
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

3. **Use AWS Profile:**
   ```bash
   export AWS_PROFILE=your-profile
   ```

4. **Check IAM permissions:**
   ```bash
   aws iam get-user
   ```

### Issue: Variables not being recognized

**Symptoms:**
```
Error: Unassigned variable
```

**Solutions:**

1. **Create terraform.tfvars:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Pass variables explicitly:**
   ```bash
   terraform apply -var="variable_name=value"
   ```

3. **Use environment variables:**
   ```bash
   export TF_VAR_variable_name="value"
   ```

### Issue: Module source not found

**Symptoms:**
```
Error: Module not installed
```

**Solutions:**

1. **Check module path:**
   ```hcl
   # Relative path
   source = "./modules/vpc"
   
   # Git URL
   source = "github.com/user/repo//modules/vpc"
   ```

2. **Re-initialize:**
   ```bash
   terraform init -upgrade
   ```

---

## Module-Specific Issues

### VPC Module

#### Issue: NAT Gateway creation timeout

**Symptoms:**
```
Error: timeout while waiting for state to become 'available'
```

**Solutions:**

1. **Increase timeout:**
   ```hcl
   timeouts {
     create = "20m"
   }
   ```

2. **Check EIP limits:**
   ```bash
   aws ec2 describe-account-attributes --attribute-names max-elastic-ips
   ```

3. **Request limit increase:**
   - AWS Console → Service Quotas → EC2 → Elastic IPs

#### Issue: Subnet CIDR conflicts

**Symptoms:**
```
Error: InvalidSubnet.Conflict
```

**Solutions:**

1. **Verify CIDR ranges don't overlap:**
   ```hcl
   vpc_cidr             = "10.0.0.0/16"
   public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
   private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
   ```

2. **Use CIDR calculator:** [Visual Subnet Calculator](https://www.davidc.net/sites/default/subnets/subnets.html)

### S3 Module

#### Issue: Bucket name already exists

**Symptoms:**
```
Error: BucketAlreadyExists: The requested bucket name is not available
```

**Solutions:**

1. **Use unique suffix:**
   ```hcl
   resource "random_id" "suffix" {
     byte_length = 4
   }
   
   bucket_name = "my-bucket-${random_id.suffix.hex}"
   ```

2. **Check global namespace:**
   ```bash
   aws s3 ls s3://your-bucket-name 2>&1 | grep -q "NoSuchBucket"
   ```

#### Issue: Public access block prevents access

**Symptoms:**
```
Error: AccessDenied when accessing bucket
```

**Solutions:**

1. **Review public access settings:**
   ```hcl
   block_public_acls       = false  # Only if needed
   block_public_policy     = false  # Only if needed
   ignore_public_acls      = false  # Only if needed
   restrict_public_buckets = false  # Only if needed
   ```

2. **Add bucket policy:**
   ```hcl
   resource "aws_s3_bucket_policy" "public_read" {
     bucket = module.bucket.bucket_id
     policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Sid       = "PublicRead"
         Effect    = "Allow"
         Principal = "*"
         Action    = "s3:GetObject"
         Resource  = "${module.bucket.bucket_arn}/*"
       }]
     })
   }
   ```

### EC2 Module

#### Issue: AMI not found

**Symptoms:**
```
Error: no AMI found matching filters
```

**Solutions:**

1. **Specify AMI explicitly:**
   ```hcl
   ami_id = "ami-0c55b159cbfafe1f0"
   ```

2. **Update AMI filters:**
   ```hcl
   ami_name_filter = "amzn2-ami-hvm-*-x86_64-gp2"
   ami_owner       = "amazon"
   ```

3. **Check region:**
   ```bash
   aws ec2 describe-images --owners amazon \
     --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
     --query 'Images[0].ImageId' --output text
   ```

#### Issue: Instance fails to start

**Symptoms:**
```
Status: running → stopped
Status checks: 0/2 checks passed
```

**Solutions:**

1. **Check user data logs:**
   ```bash
   aws ssm start-session --target i-1234567890abcdef0
   sudo cat /var/log/cloud-init-output.log
   ```

2. **Review instance logs:**
   ```bash
   aws ec2 get-console-output --instance-id i-1234567890abcdef0
   ```

3. **Verify security group:**
   ```bash
   aws ec2 describe-security-groups --group-ids sg-12345678
   ```

### RDS Module

#### Issue: Database creation timeout

**Symptoms:**
```
Error: timeout while waiting for state to become 'available'
```

**Solutions:**

1. **Increase timeout:**
   ```hcl
   timeouts {
     create = "60m"
     update = "60m"
     delete = "60m"
   }
   ```

2. **Start with smaller instance:**
   ```hcl
   instance_class = "db.t3.micro"  # Then scale up
   ```

3. **Check subnet group:**
   ```bash
   aws rds describe-db-subnet-groups
   ```

#### Issue: Cannot delete with deletion protection

**Symptoms:**
```
Error: InvalidParameterValue: Cannot delete protected DB Instance
```

**Solutions:**

1. **Disable protection first:**
   ```hcl
   deletion_protection = false
   ```

2. **Apply and then destroy:**
   ```bash
   terraform apply -auto-approve
   terraform destroy
   ```

3. **Manual override:**
   ```bash
   aws rds modify-db-instance \
     --db-instance-identifier my-db \
     --no-deletion-protection
   ```

### ALB Module

#### Issue: Certificate validation timeout

**Symptoms:**
```
Error: timeout while waiting for ACM Certificate validation
```

**Solutions:**

1. **Verify DNS records:**
   ```bash
   aws acm describe-certificate --certificate-arn arn:aws:acm:...
   ```

2. **Add CNAME records manually:**
   ```bash
   # Get validation CNAME from ACM console
   ```

3. **Use DNS validation:**
   ```hcl
   validation_method = "DNS"
   ```

#### Issue: Target group has no healthy targets

**Symptoms:**
```
All targets failing health checks
```

**Solutions:**

1. **Check health check path:**
   ```hcl
   health_check = {
     path    = "/health"  # Ensure this endpoint exists
     matcher = "200"
   }
   ```

2. **Verify security groups:**
   ```bash
   # Allow ALB to reach targets
   aws ec2 authorize-security-group-ingress \
     --group-id sg-target \
     --source-group sg-alb \
     --protocol tcp --port 80
   ```

3. **Review logs:**
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn arn:aws:elasticloadbalancing:...
   ```

### EKS Module

#### Issue: Cluster creation fails

**Symptoms:**
```
Error: error creating EKS Cluster: UnsupportedAvailabilityZoneException
```

**Solutions:**

1. **Use different AZs:**
   ```hcl
   availability_zones = ["us-east-1a", "us-east-1b"]
   # Avoid us-east-1e for EKS
   ```

2. **Check EKS support:**
   ```bash
   aws eks describe-addon-versions --kubernetes-version 1.28
   ```

3. **Verify service limits:**
   ```bash
   aws service-quotas list-service-quotas \
     --service-code eks
   ```

#### Issue: Node group fails to create

**Symptoms:**
```
Error: NodeCreationFailure: Instances failed to join the cluster
```

**Solutions:**

1. **Check node IAM role:**
   ```bash
   aws iam get-role --role-name eks-node-role
   ```

2. **Verify security groups:**
   ```bash
   # Nodes must communicate with control plane
   aws eks describe-cluster --name my-cluster
   ```

3. **Review node logs:**
   ```bash
   aws ec2 get-console-output --instance-id i-1234567890abcdef0
   ```

#### Issue: Cannot configure kubectl

**Symptoms:**
```
error: You must be logged in to the server (Unauthorized)
```

**Solutions:**

1. **Update kubeconfig:**
   ```bash
   aws eks update-kubeconfig \
     --name my-cluster \
     --region us-east-1
   ```

2. **Verify IAM permissions:**
   ```bash
   aws eks describe-cluster --name my-cluster
   ```

3. **Check aws-auth ConfigMap:**
   ```bash
   kubectl get configmap aws-auth -n kube-system -o yaml
   ```

---

## AWS-Related Issues

### Issue: Rate limiting / throttling

**Symptoms:**
```
Error: RequestLimitExceeded: Request rate limit exceeded
```

**Solutions:**

1. **Add retry logic:**
   ```hcl
   provider "aws" {
     max_retries = 10
   }
   ```

2. **Reduce parallelism:**
   ```bash
   terraform apply -parallelism=5
   ```

3. **Request limit increase:**
   - AWS Console → Service Quotas

### Issue: Insufficient permissions

**Symptoms:**
```
Error: AccessDeniedException: User is not authorized
```

**Solutions:**

1. **Check IAM policy:**
   ```bash
   aws iam simulate-principal-policy \
     --policy-source-arn arn:aws:iam::123456789012:user/terraform \
     --action-names ec2:CreateVpc
   ```

2. **Add required permissions:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Action": [
         "ec2:*",
         "rds:*",
         "s3:*",
         "eks:*",
         "iam:*"
       ],
       "Resource": "*"
     }]
   }
   ```

3. **Use admin temporarily:**
   ```bash
   # Determine exact permissions needed, then restrict
   ```

### Issue: Resource limits exceeded

**Symptoms:**
```
Error: VcpuLimitExceeded: You have exceeded your maximum vCPU limit
```

**Solutions:**

1. **Check current limits:**
   ```bash
   aws service-quotas list-service-quotas \
     --service-code ec2 \
     --query 'Quotas[?QuotaName==`Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances`]'
   ```

2. **Request increase:**
   - AWS Console → Service Quotas → EC2 → Request increase

3. **Use different instance types:**
   ```hcl
   instance_type = "t3.small"  # Instead of larger types
   ```

---

## Terraform State Issues

### Issue: State file locked

**Symptoms:**
```
Error: Error acquiring the state lock
```

**Solutions:**

1. **Wait for other operations:**
   ```bash
   # Another terraform operation may be running
   ```

2. **Force unlock (dangerous):**
   ```bash
   terraform force-unlock LOCK_ID
   ```

3. **Check S3 backend DynamoDB:**
   ```bash
   aws dynamodb scan --table-name terraform-locks
   ```

### Issue: State drift detected

**Symptoms:**
```
Resource has been modified outside of Terraform
```

**Solutions:**

1. **Refresh state:**
   ```bash
   terraform refresh
   ```

2. **Import resource:**
   ```bash
   terraform import module.vpc.aws_vpc.main vpc-12345678
   ```

3. **Update configuration to match:**
   ```bash
   terraform plan
   # Review differences and update code
   ```

### Issue: Cannot destroy resources

**Symptoms:**
```
Error: DependencyViolation
```

**Solutions:**

1. **Destroy in order:**
   ```bash
   terraform destroy -target=module.ec2
   terraform destroy -target=module.alb
   terraform destroy -target=module.vpc
   ```

2. **Remove from state:**
   ```bash
   terraform state rm module.stuck_resource
   # Then manually delete in AWS
   ```

3. **Force recreate:**
   ```bash
   terraform taint module.resource.aws_instance.example
   terraform apply
   ```

---

## Performance Issues

### Issue: Slow plan/apply

**Symptoms:**
- Plans take > 5 minutes
- Apply takes > 30 minutes

**Solutions:**

1. **Reduce parallelism:**
   ```bash
   terraform plan -parallelism=5
   ```

2. **Split into smaller modules:**
   ```hcl
   # Instead of one large module, use multiple smaller ones
   ```

3. **Use targeted operations:**
   ```bash
   terraform apply -target=module.vpc
   ```

### Issue: Large state file

**Symptoms:**
- State file > 10MB
- Slow refresh operations

**Solutions:**

1. **Split state files:**
   ```hcl
   # Use separate state files per environment
   ```

2. **Use workspaces:**
   ```bash
   terraform workspace new production
   terraform workspace new staging
   ```

3. **Remove unused resources:**
   ```bash
   terraform state list
   terraform state rm unused.resource
   ```

---

## Debugging Techniques

### Enable Terraform debugging

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
terraform apply
```

### Verbose AWS CLI output

```bash
aws --debug ec2 describe-instances 2> aws-debug.log
```

### Test module in isolation

```bash
cd modules/vpc
terraform init
terraform plan -var-file=../../terraform.tfvars
```

### Validate JSON/HCL syntax

```bash
# Validate Terraform
terraform validate

# Format code
terraform fmt -recursive

# Validate JSON
cat file.json | jq empty

# Validate YAML
yamllint file.yaml
```

### Check provider versions

```bash
terraform providers
terraform version
```

### Review Terraform graph

```bash
terraform graph | dot -Tpng > graph.png
```

---

## Getting Help

### Before asking for help:

1. ✅ Search existing issues
2. ✅ Check documentation
3. ✅ Enable debug logging
4. ✅ Try in clean environment
5. ✅ Document steps to reproduce

### When asking for help:

Include:
- Terraform version
- Provider versions
- Module version
- Error messages (full output)
- Debug logs (sanitized)
- Configuration (sanitized)
- Steps to reproduce

### Resources:

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Issues](https://github.com/jaaparjazzery/aws-terraform-modules/issues)
- [GitHub Discussions](https://github.com/jaaparjazzery/aws-terraform-modules/discussions)

---

## Common Error Messages

### Authentication Errors

| Error | Meaning | Solution |
|-------|---------|----------|
| `NoCredentialProviders` | No AWS credentials found | Configure AWS CLI or set env vars |
| `InvalidClientTokenId` | Invalid access key | Check AWS_ACCESS_KEY_ID |
| `SignatureDoesNotMatch` | Invalid secret key | Check AWS_SECRET_ACCESS_KEY |
| `ExpiredToken` | Session token expired | Refresh credentials |

### Permission Errors

| Error | Meaning | Solution |
|-------|---------|----------|
| `AccessDenied` | Insufficient IAM permissions | Add required IAM policies |
| `UnauthorizedOperation` | Action not allowed | Check IAM permissions |
| `Forbidden` | Resource access denied | Review resource policies |

### Resource Errors

| Error | Meaning | Solution |
|-------|---------|----------|
| `ResourceInUse` | Resource still in use | Delete dependent resources first |
| `DependencyViolation` | Dependencies exist | Remove dependencies |
| `ResourceNotFound` | Resource doesn't exist | Check resource ID |
| `InvalidParameterValue` | Invalid parameter | Check parameter format |

---

**Remember:** Most issues can be resolved by carefully reading error messages and checking AWS console! 🔍
