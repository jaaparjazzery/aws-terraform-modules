# modules/apigateway/variables.tf

variable "name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "api_type" {
  description = "API type (REST, HTTP, or WEBSOCKET)"
  type        = string
  default     = "REST"
  validation {
    condition     = contains(["REST", "HTTP", "WEBSOCKET"], var.api_type)
    error_message = "API type must be REST, HTTP, or WEBSOCKET."
  }
}

variable "endpoint_types" {
  description = "List of endpoint types (EDGE, REGIONAL, or PRIVATE)"
  type        = list(string)
  default     = ["REGIONAL"]
}

variable "vpc_endpoint_ids" {
  description = "List of VPC endpoint IDs (for PRIVATE endpoints)"
  type        = list(string)
  default     = []
}

variable "binary_media_types" {
  description = "List of binary media types supported by the REST API"
  type        = list(string)
  default     = []
}

variable "minimum_compression_size" {
  description = "Minimum response size to compress for the REST API"
  type        = number
  default     = -1
}

variable "api_key_source" {
  description = "Source of the API key for requests (HEADER or AUTHORIZER)"
  type        = string
  default     = "HEADER"
}

variable "disable_execute_api_endpoint" {
  description = "Whether clients can invoke the API using the default execute-api endpoint"
  type        = bool
  default     = false
}

variable "policy" {
  description = "JSON formatted policy document for the API"
  type        = string
  default     = null
}

variable "api_version" {
  description = "Version identifier for the API"
  type        = string
  default     = null
}

variable "route_selection_expression" {
  description = "Route selection expression for the API"
  type        = string
  default     = "$request.method $request.path"
}

variable "api_key_selection_expression" {
  description = "API key selection expression"
  type        = string
  default     = "$request.header.x-api-key"
}

variable "cors_configuration" {
  description = "CORS configuration for HTTP API"
  type = object({
    allow_credentials = optional(bool)
    allow_headers     = optional(list(string))
    allow_methods     = optional(list(string))
    allow_origins     = optional(list(string))
    expose_headers    = optional(list(string))
    max_age           = optional(number)
  })
  default = null
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "prod"
}

variable "stage_description" {
  description = "Description of the API Gateway stage"
  type        = string
  default     = ""
}

variable "auto_deploy" {
  description = "Whether updates to an API automatically trigger a new deployment"
  type        = bool
  default     = true
}

variable "cache_cluster_enabled" {
  description = "Whether a cache cluster is enabled for the stage"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "Size of the cache cluster (0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237)"
  type        = string
  default     = "0.5"
}

variable "xray_tracing_enabled" {
  description = "Whether X-Ray tracing is enabled for the stage"
  type        = bool
  default     = false
}

variable "access_log_settings" {
  description = "Access log settings"
  type = object({
    destination_arn = string
    format          = string
  })
  default = null
}

variable "default_route_settings" {
  description = "Default route settings for HTTP/WebSocket API"
  type = object({
    data_trace_enabled       = optional(bool)
    detailed_metrics_enabled = optional(bool)
    logging_level            = optional(string)
    throttling_burst_limit   = optional(number)
    throttling_rate_limit    = optional(number)
  })
  default = null
}

variable "stage_variables" {
  description = "Map of stage variables"
  type        = map(string)
  default     = {}
}

variable "deployment_triggers" {
  description = "Map of arbitrary keys and values that trigger a new deployment"
  type        = any
  default     = {}
}

variable "domain_name" {
  description = "Custom domain name for the API"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
  default     = null
}

variable "security_policy" {
  description = "Security policy for the domain (TLS_1_0 or TLS_1_2)"
  type        = string
  default     = "TLS_1_2"
}

variable "base_path" {
  description = "Base path for the API mapping"
  type        = string
  default     = ""
}

variable "usage_plans" {
  description = "Map of usage plans"
  type = map(object({
    description            = optional(string)
    quota_limit            = optional(number)
    quota_period           = optional(string)
    throttle_burst_limit   = optional(number)
    throttle_rate_limit    = optional(number)
  }))
  default = {}
}

variable "api_keys" {
  description = "Map of API keys"
  type = map(object({
    description = optional(string)
    enabled     = optional(bool)
    value       = optional(string)
  }))
  default = {}
}

variable "usage_plan_keys" {
  description = "Map of usage plan key associations"
  type = map(object({
    api_key_name     = string
    usage_plan_name  = string
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

variable "web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL to associate"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}