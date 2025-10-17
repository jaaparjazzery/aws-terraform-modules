# modules/elasticache/variables.tf

variable "engine" {
  description = "Cache engine (redis or memcached)"
  type        = string
  default     = "redis"
  validation {
    condition     = contains(["redis", "memcached"], var.engine)
    error_message = "Engine must be redis or memcached."
  }
}

variable "replication_group_id" {
  description = "Replication group identifier (Redis)"
  type        = string
  default     = ""
}

variable "cluster_id" {
  description = "Cluster identifier (Memcached)"
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the replication group"
  type        = string
  default     = ""
}

variable "engine_version" {
  description = "Version of the cache engine"
  type        = string
  default     = "7.0"
}

variable "node_type" {
  description = "Instance type of the cache nodes"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (Redis, non-cluster mode)"
  type        = number
  default     = 1
}

variable "num_cache_nodes" {
  description = "Number of cache nodes (Memcached)"
  type        = number
  default     = 1
}

variable "port" {
  description = "Port number on which the cache accepts connections"
  type        = number
  default     = null
}

variable "create_subnet_group" {
  description = "Whether to create subnet group"
  type        = bool
  default     = true
}

variable "subnet_group_name" {
  description = "Name of the subnet group"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "create_parameter_group" {
  description = "Whether to create parameter group"
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Name of the parameter group"
  type        = string
  default     = ""
}

variable "parameter_group_family" {
  description = "Parameter group family"
  type        = string
  default     = "redis7"
}

variable "parameters" {
  description = "List of parameters"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (Redis)"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ (Redis)"
  type        = bool
  default     = true
}

variable "cluster_mode_enabled" {
  description = "Enable cluster mode (Redis)"
  type        = bool
  default     = false
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit"
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Auth token for Redis AUTH"
  type        = string
  default     = null
  sensitive   = true
}

variable "kms_key_id" {
  description = "ARN of the KMS key for encryption"
  type        = string
  default     = null
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 5
}

variable "snapshot_window" {
  description = "Daily time range for snapshots"
  type        = string
  default     = "03:00-05:00"
}

variable "maintenance_window" {
  description = "Weekly time range for maintenance"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "notification_topic_arn" {
  description = "ARN of SNS topic for notifications"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "data_tiering_enabled" {
  description = "Enable data tiering (Redis)"
  type        = bool
  default     = false
}

variable "az_mode" {
  description = "AZ mode (single-az or cross-az) for Memcached"
  type        = string
  default     = "single-az"
}

variable "preferred_availability_zones" {
  description = "List of preferred availability zones (Memcached)"
  type        = list(string)
  default     = []
}

variable "log_delivery_configuration" {
  description = "Log delivery configuration"
  type = list(object({
    destination      = string
    destination_type = string
    log_format       = string
    log_type         = string
  }))
  default = []
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "users" {
  description = "Map of Redis users"
  type = map(object({
    user_name     = string
    access_string = string
    passwords     = optional(list(string))
  }))
  default = null
}

variable "user_group_id" {
  description = "User group ID (Redis)"
  type        = string
  default     = null
}

variable "user_ids" {
  description = "List of user IDs in the user group"
  type        = list(string)
  default     = []
}

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms"
  type        = bool
  default     = false
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization alarm threshold"
  type        = number
  default     = 75
}

variable "memory_alarm_threshold" {
  description = "Memory usage alarm threshold"
  type        = number
  default     = 10
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}