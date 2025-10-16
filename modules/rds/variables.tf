variable "db_identifier" {
  description = "Database identifier"
  type        = string
}

variable "engine" {
  description = "Database engine (postgres, mysql, mariadb, etc.)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "major_engine_version" {
  description = "Major engine version for option group"
  type        = string
  default     = null
}

variable "instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "IOPS for io1/io2 storage type"
  type        = number
  default     = null
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "database_name" {
  description = "Name of the default database"
  type        = string
}

variable "master_username" {
  description = "Master username"
  type        = string
}

variable "master_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "database_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

variable "parameter_group_name" {
  description = "Existing parameter group name (if null, one will be created)"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "Parameter group family"
  type        = string
  default     = "postgres15"
}

variable "db_parameters" {
  description = "Database parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "option_group_name" {
  description = "Existing option group name"
  type        = string
  default     = null
}

variable "db_options" {
  description = "Database options"
  type = list(object({
    option_name = string
    option_settings = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = []
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Make database publicly accessible"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability zone (only used for single-AZ deployments)"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for enhanced monitoring"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "KMS key ID for Performance Insights"
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrades"
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Allow major version upgrades"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "ca_cert_identifier" {
  description = "Certificate authority identifier"
  type        = string
  default     = null
}

variable "create_read_replica" {
  description = "Create read replicas"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 1
}

variable "replica_instance_class" {
  description = "Instance class for read replicas (defaults to same as primary)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
