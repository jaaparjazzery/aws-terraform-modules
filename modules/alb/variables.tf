variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs (must be in at least 2 AZs)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for target groups"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid header fields"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Idle timeout in seconds"
  type        = number
  default     = 60
}

variable "access_logs_bucket" {
  description = "S3 bucket for access logs"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 prefix for access logs"
  type        = string
  default     = ""
}

variable "enable_http_listener" {
  description = "Enable HTTP listener"
  type        = bool
  default     = true
}

variable "http_port" {
  description = "HTTP port"
  type        = number
  default     = 80
}

variable "http_redirect_to_https" {
  description = "Redirect HTTP to HTTPS"
  type        = bool
  default     = true
}

variable "enable_https_listener" {
  description = "Enable HTTPS listener"
  type        = bool
  default     = true
}

variable "https_port" {
  description = "HTTPS port"
  type        = number
  default     = 443
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
  default     = null
}

variable "additional_certificates" {
  description = "Map of additional SSL certificate ARNs"
  type        = map(string)
  default     = {}
}

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    name     = string
    port     = number
    protocol = string
    target_type = string
    deregistration_delay = optional(number, 300)
    health_check = object({
      enabled             = bool
      path                = string
      protocol            = string
      matcher             = string
      interval            = number
      timeout             = number
      healthy_threshold   = number
      unhealthy_threshold = number
    })
    stickiness = object({
      type            = string
      cookie_duration = number
      enabled         = bool
    })
  }))
}

variable "default_target_group_key" {
  description = "Key of the default target group"
  type        = string
  default     = null
}

variable "listener_rules" {
  description = "Map of listener rules for routing"
  type = map(object({
    priority         = number
    action_type      = string
    target_group_key = optional(string)
    redirect_config = optional(object({
      protocol    = string
      port        = string
      host        = optional(string, "#{host}")
      path        = optional(string, "/#{path}")
      query       = optional(string, "#{query}")
      status_code = string
    }))
    fixed_response_config = optional(object({
      content_type = string
      message_body = optional(string)
      status_code  = string
    }))
    conditions = list(object({
      host_header         = optional(list(string))
      path_pattern        = optional(list(string))
      http_request_method = optional(list(string))
      source_ip           = optional(list(string))
    }))
  }))
  default = {}
}

variable "target_attachments" {
  description = "Map of static target attachments"
  type = map(object({
    target_group_key = string
    target_id        = string
    port             = optional(number)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
