# modules/ecr/variables.tf

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string
  default     = null
}

variable "scan_on_push" {
  description = "Whether to scan images on push"
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "Whether to force delete repository even if it contains images"
  type        = bool
  default     = false
}

variable "lifecycle_policy" {
  description = "JSON formatted lifecycle policy"
  type        = string
  default     = null
}

variable "repository_policy" {
  description = "JSON formatted repository policy"
  type        = string
  default     = null
}

variable "replication_configuration" {
  description = "Replication configuration"
  type = list(object({
    destinations = list(object({
      region      = string
      registry_id = string
    }))
    repository_filters = optional(list(object({
      filter      = string
      filter_type = string
    })))
  }))
  default = null
}

variable "pull_through_cache_rules" {
  description = "Map of pull through cache rules"
  type = map(object({
    ecr_repository_prefix = string
    upstream_registry_url = string
  }))
  default = {}
}

variable "create_log_group" {
  description = "Whether to create CloudWatch log group"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 7
}

variable "log_kms_key_id" {
  description = "KMS key ID to encrypt CloudWatch logs"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}