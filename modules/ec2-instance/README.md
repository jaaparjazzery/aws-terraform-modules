# AWS EC2 Instance Terraform Module

This module creates an AWS EC2 instance with configurable options including EBS volumes, monitoring, and security settings.

## Features

- Automatic AMI selection or manual AMI specification
- Flexible EBS volume configuration
- IMDSv2 enforcement for enhanced security
- Support for Elastic IP
- Detailed monitoring option
- User data support
- CPU credits configuration for burstable instances
- Termination protection
- Comprehensive tagging

## Usage

### Basic Example

```hcl
module "web_server" {
  source = "./modules/ec2-instance"

  instance_name      = "web-server-01"
  instance_type      = "t3.small"
  subnet_id          = "subnet-12345678"
  security_group_ids = ["sg-12345678"]
  key_name           = "my-key-pair"
  
  associate_public_ip = true
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF
  
  tags = {
    Environment = "production"
    Application = "web"
  }
}
```

### Advanced Example with Additional EBS Volumes

```hcl
module "app_server" {
  source = "./modules/ec2-instance"

  instance_name      = "app-server-01"
  instance_type      = "t3.medium"
  subnet_id          = "subnet-12345678"
  security_group_ids = ["sg-12345678"]
  key_name           = "my-key-pair"
  
  # Use specific AMI
  ami_id = "ami-0c55b159cbfafe1f0"
  
  # Root volume configuration
  root_volume_type       = "gp3"
  root_volume_size       = 50
  root_volume_throughput = 200
  root_volume_encrypted  = true
  
  # Additional EBS volumes
  ebs_volumes = [
    {
      device_name           = "/dev/sdf"
      volume_type           = "gp3"
      volume_size           = 100
      throughput            = 250
      delete_on_termination = true
      encrypted             = true
    },
    {
      device_name           = "/dev/sdg"
      volume_type           = "io2"
      volume_size           = 200
      iops                  = 10000
      delete_on_termination = false
      encrypted             = true
    }
  ]
  
  # IAM role for EC2
  iam_instance_profile = "my-instance-profile"
  
  # Enable detailed monitoring
  enable_detailed_monitoring = true
  
  # Elastic IP
  create_eip = true
  
  # Enhanced security
  require_imdsv2 = true
  
  # Termination protection
  disable_api_termination = true
  
  tags = {
    Environment = "production"
    Application = "database"
    Backup      = "daily"
  }
}
```

### Example with Custom AMI Lookup

```hcl
module "ubuntu_server" {
  source = "./modules/ec2-instance"

  instance_name      = "ubuntu-server"
  instance_type      = "t3.micro"
  subnet_id          = "subnet-12345678"
  security_group_ids = ["sg-12345678"]
  
  # Look up Ubuntu AMI
  ami_owner       = "099720109477" # Canonical
  ami_name_filter = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  
  tags = {
    Environment = "development"
  }
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| instance_name | Name of the EC2 instance | string | n/a | yes |
| instance_type | EC2 instance type | string | "t3.micro" | no |
| subnet_id | Subnet ID for the instance | string | n/a | yes |
| security_group_ids | List of security group IDs | list(string) | n/a | yes |
| ami_id | AMI ID to use | string | null | no |
| ami_owner | Owner ID for AMI lookup | string | "amazon" | no |
| ami_name_filter | Name filter for AMI lookup | string | "amzn2-ami-hvm-*-x86_64-gp2" | no |
| key_name | SSH key pair name | string | null | no |
| associate_public_ip | Associate a public IP address | bool | false | no |
| create_eip | Create and associate an Elastic IP | bool | false | no |
| root_volume_type | Root volume type | string | "gp3" | no |
| root_volume_size | Root volume size in GB | number | 20 | no |
| root_volume_encrypted | Encrypt root volume | bool | true | no |
| enable_detailed_monitoring | Enable detailed monitoring | bool | false | no |
| require_imdsv2 | Require IMDSv2 for instance metadata | bool | true | no |
| disable_api_termination | Enable termination protection | bool | false | no |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | ID of the EC2 instance |
| instance_arn | ARN of the EC2 instance |
| private_ip | Private IP address |
| public_ip | Public IP address |
| eip_public_ip | Elastic IP address (if created) |
| instance_state | State of the instance |
| ami_id | AMI ID used |
| availability_zone | Availability zone |
