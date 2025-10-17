# modules/lambda/variables.tf

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Function entrypoint in your code"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Runtime environment for the Lambda function"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Memory size in MB"
  type        = number
  default     = 128
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version"
  type        = bool
  default     = false
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs to attach"
  type        = list(string)
  default     = []
}

variable "architectures" {
  description = "Instruction set architecture for Lambda function"
  type        = list(string)
  default     = ["x86_64"]
}

variable "filename" {
  description = "Path to the function's deployment package within the local filesystem"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket location containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of an object containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Object version containing the function's deployment package"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI containing the function's deployment package"
  type        = string
  default     = null
}

variable "package_type" {
  description = "Lambda deployment package type (Zip or Image)"
  type        = string
  default     = "Zip"
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions for this lambda function"
  type        = number
  default     = -1
}

variable "environment_variables" {
  description = "Map of environment variables"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "dead_letter_target_arn" {
  description = "ARN of an SNS topic or SQS queue to notify when an invocation fails"
  type        = string
  default     = null
}

variable "tracing_mode" {
  description = "X-Ray tracing mode (Active or PassThrough)"
  type        = string
  default     = null
}

variable "ephemeral_storage_size" {
  description = "Amount of ephemeral storage (/tmp) in MB"
  type        = number
  default     = null
}

variable "create_role" {
  description = "Whether to create an IAM role for the Lambda function"
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "ARN of existing IAM role to use (if create_role is false)"
  type        = string
  default     = null
}

variable "custom_policies" {
  description = "List of custom IAM policy documents"
  type        = list(string)
  default     = null
}

variable "lambda_permissions" {
  description = "Map of Lambda permissions to create"
  type = map(object({
    action         = string
    principal      = string
    source_arn     = optional(string)
    source_account = optional(string)
  }))
  default = {}
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

variable "aliases" {
  description = "Map of Lambda aliases to create"
  type = map(object({
    description      = optional(string)
    function_version = optional(string)
    routing_config = optional(object({
      additional_version_weights = map(number)
    }))
  }))
  default = {}
}

variable "schedules" {
  description = "Map of EventBridge schedules to create"
  type = map(object({
    schedule_expression = string
    description         = optional(string)
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