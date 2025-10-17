# modules/waf/variables.tf

variable "name" {
  description = "Name of the WAF Web ACL"
  type        = string
}

variable "description" {
  description = "Description of the WAF Web ACL"
  type        = string
  default     = ""
}

variable "scope" {
  description = "Scope of the WAF (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "default_action" {
  description = "Default action for requests (allow or block)"
  type        = string
  default     = "allow"
}

variable "default_block_custom_response" {
  description = "Custom response for default block action"
  type = object({
    response_code = number
    response_headers = optional(list(object({
      name  = string
      value = string
    })))
  })
  default = null
}

variable "rules" {
  description = "List of WAF rules"
  type = list(object({
    name     = string
    priority = number
    action   = optional(string)
    override_action = optional(string)
    statement = any
    cloudwatch_metrics_enabled = optional(bool)
    sampled_requests_enabled   = optional(bool)
    custom_response = optional(object({
      response_code = number
      response_headers = optional(list(object({
        name  = string
        value = string
      })))
    }))
  }))
  default = []
}

variable "ip_sets" {
  description = "Map of IP sets to create"
  type = map(object({
    description        = optional(string)
    ip_address_version = string
    addresses          = list(string)
  }))
  default = {}
}

variable "regex_pattern_sets" {
  description = "Map of regex pattern sets to create"
  type = map(object({
    description = optional(string)
    patterns    = list(string)
  }))
  default = {}
}

variable "cloudwatch_metrics_enabled" {
  description = "Whether CloudWatch metrics are enabled for the Web ACL"
  type        = bool
  default     = true
}

variable "sampled_requests_enabled" {
  description = "Whether sampled requests are enabled for the Web ACL"
  type        = bool
  default     = true
}

variable "logging_configuration" {
  description = "Logging configuration for the Web ACL"
  type = object({
    log_destination_configs = list(string)
    redacted_fields = optional(list(object({
      single_header = optional(string)
      uri_path      = optional(bool)
      query_string  = optional(bool)
    })))
  })
  default = null
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