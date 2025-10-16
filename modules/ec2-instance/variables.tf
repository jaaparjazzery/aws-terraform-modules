variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use (if null, latest AMI matching filter will be used)"
  type        = string
  default     = null
}

variable "ami_owner" {
  description = "Owner ID for AMI lookup"
  type        = string
  default     = "amazon"
}

variable "ami_name_filter" {
  description = "Name filter for AMI lookup"
  type        = string
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Associate a public IP address"
  type        = bool
  default     = false
}

variable "create_eip" {
  description = "Create and associate an Elastic IP"
  type        = bool
  default     = false
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script"
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Replace instance when user data changes"
  type        = bool
  default     = false
}

variable "root_volume_type" {
  description = "Root volume type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "root_volume_iops" {
  description = "Root volume IOPS (only for io1/io2)"
  type        = number
  default     = null
}

variable "root_volume_throughput" {
  description = "Root volume throughput in MB/s (only for gp3)"
  type        = number
  default     = null
}

variable "root_volume_delete_on_termination" {
  description = "Delete root volume on instance termination"
  type        = bool
  default     = true
}

variable "root_volume_encrypted" {
  description = "Encrypt root volume"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for EBS encryption"
  type        = string
  default     = null
}

variable "ebs_volumes" {
  description = "Additional EBS volumes"
  type = list(object({
    device_name           = string
    volume_type           = string
    volume_size           = number
    iops                  = optional(number)
    throughput            = optional(number)
    delete_on_termination = bool
    encrypted             = bool
  }))
  default = []
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "require_imdsv2" {
  description = "Require IMDSv2 for instance metadata"
  type        = bool
  default     = true
}

variable "metadata_hop_limit" {
  description = "Metadata service hop limit"
  type        = number
  default     = 1
}

variable "enable_metadata_tags" {
  description = "Enable instance metadata tags"
  type        = bool
  default     = false
}

variable "cpu_credits" {
  description = "CPU credit option for burstable instances (standard or unlimited)"
  type        = string
  default     = "standard"
  
  validation {
    condition     = contains(["standard", "unlimited"], var.cpu_credits)
    error_message = "CPU credits must be either 'standard' or 'unlimited'"
  }
}

variable "disable_api_termination" {
  description = "Enable EC2 Instance Termination Protection"
  type        = bool
  default     = false
}

variable "ignore_ami_changes" {
  description = "Ignore AMI changes (useful to prevent recreation on AMI updates)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
