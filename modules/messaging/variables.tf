# modules/messaging/variables.tf

variable "sns_topics" {
  description = "Map of SNS topics to create"
  type = map(object({
    display_name                = optional(string)
    fifo_topic                  = optional(bool)
    content_based_deduplication = optional(bool)
    kms_master_key_id           = optional(string)
    delivery_policy             = optional(string)
  }))
  default = {}
}

variable "sns_topic_policies" {
  description = "Map of SNS topic policies"
  type        = map(string)
  default     = {}
}

variable "sns_subscriptions" {
  description = "Map of SNS subscriptions"
  type = map(object({
    topic_name                      = string
    protocol                        = string
    endpoint                        = string
    filter_policy                   = optional(string)
    filter_policy_scope             = optional(string)
    raw_message_delivery            = optional(bool)
    redrive_policy                  = optional(string)
    subscription_role_arn           = optional(string)
    delivery_policy                 = optional(string)
    endpoint_auto_confirms          = optional(bool)
    confirmation_timeout_in_minutes = optional(number)
  }))
  default = {}
}

variable "sqs_queues" {
  description = "Map of SQS queues to create"
  type = map(object({
    fifo_queue                        = optional(bool)
    content_based_deduplication       = optional(bool)
    delay_seconds                     = optional(number)
    max_message_size                  = optional(number)
    message_retention_seconds         = optional(number)
    receive_wait_time_seconds         = optional(number)
    visibility_timeout_seconds        = optional(number)
    kms_master_key_id                 = optional(string)
    kms_data_key_reuse_period_seconds = optional(number)
    deduplication_scope               = optional(string)
    fifo_throughput_limit             = optional(string)
    sqs_managed_sse_enabled           = optional(bool)
    age_alarm_threshold               = optional(number)
    depth_alarm_threshold             = optional(number)
  }))
  default = {}
}

variable "sqs_dead_letter_queues" {
  description = "Map of SQS dead letter queues to create"
  type = map(object({
    fifo_queue                = optional(bool)
    message_retention_seconds = optional(number)
    kms_master_key_id         = optional(string)
    sqs_managed_sse_enabled   = optional(bool)
  }))
  default = {}
}

variable "sqs_queue_policies" {
  description = "Map of SQS queue policies"
  type        = map(string)
  default     = {}
}

variable "sqs_redrive_policies" {
  description = "Map of SQS redrive policies"
  type = map(object({
    dlq_name          = string
    max_receive_count = number
  }))
  default = {}
}

variable "sqs_redrive_allow_policies" {
  description = "Map of SQS redrive allow policies for DLQs"
  type = map(object({
    redrive_permission  = string
    source_queue_names  = list(string)
  }))
  default = {}
}

variable "sns_to_sqs_subscriptions" {
  description = "Map of SNS to SQS subscriptions"
  type = map(object({
    topic_name           = string
    queue_name           = string
    raw_message_delivery = optional(bool)
    filter_policy        = optional(string)
  }))
  default = {}
}

variable "create_sqs_alarms" {
  description = "Whether to create CloudWatch alarms for SQS queues"
  type        = bool
  default     = false
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