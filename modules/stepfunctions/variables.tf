# modules/stepfunctions/variables.tf

variable "name" {
  description = "Name of the Step Functions state machine"
  type        = string
}

variable "definition" {
  description = "Amazon States Language definition of the state machine"
  type        = string
}

variable "type" {
  description = "State machine type (STANDARD or EXPRESS)"
  type        = string
  default     = "STANDARD"
}

variable "create_role" {
  description = "Whether to create an IAM role"
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "ARN of existing IAM role (if create_role is false)"
  type        = string
  default     = null
}

variable "custom_policies" {
  description = "List of custom IAM policy documents"
  type        = list(string)
  default     = null
}

variable "logging_configuration" {
  description = "Logging configuration"
  type = object({
    include_execution_data = optional(bool)
    level                  = optional(string)
  })
  default = null
}

variable "tracing_enabled" {
  description = "Whether X-Ray tracing is enabled"
  type        = bool
  default     = false
}

variable "create_log_group" {
  description = "Whether to create CloudWatch log group"
  type        = bool
  default     = true
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

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms"
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

variable "event_triggers" {
  description = "Map of EventBridge triggers"
  type = map(object({
    description         = optional(string)
    event_pattern       = optional(string)
    schedule_expression = optional(string)
    enabled             = optional(bool)
    input               = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}