# modules/cloudfront/variables.tf

variable "enabled" {
  description = "Whether the distribution is enabled"
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Comment for the CloudFront distribution"
  type        = string
  default     = ""
}

variable "default_root_object" {
  description = "Object that you want CloudFront to return when a user requests the root URL"
  type        = string
  default     = "index.html"
}

variable "aliases" {
  description = "List of CNAME aliases"
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "Price class for the distribution"
  type        = string
  default     = "PriceClass_All"
}

variable "http_version" {
  description = "Maximum HTTP version to support"
  type        = string
  default     = "http2and3"
}

variable "web_acl_id" {
  description = "AWS WAF web ACL ARN"
  type        = string
  default     = null
}

variable "retain_on_delete" {
  description = "Retain the distribution when destroying"
  type        = bool
  default     = false
}

variable "wait_for_deployment" {
  description = "Wait for the distribution to be deployed"
  type        = bool
  default     = true
}

variable "origins" {
  description = "List of origins"
  type        = list(any)
}

variable "origin_groups" {
  description = "List of origin groups"
  type = list(object({
    origin_id                    = string
    failover_status_codes        = list(number)
    primary_member_origin_id     = string
    secondary_member_origin_id   = string
  }))
  default = []
}

variable "default_cache_behavior" {
  description = "Default cache behavior"
  type        = any
}

variable "ordered_cache_behaviors" {
  description = "Ordered list of cache behaviors"
  type        = list(any)
  default     = []
}

variable "geo_restriction_type" {
  description = "Geo restriction type (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
  default     = null
}

variable "ssl_support_method" {
  description = "SSL support method (sni-only or vip)"
  type        = string
  default     = "sni-only"
}

variable "minimum_protocol_version" {
  description = "Minimum SSL/TLS protocol version"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "logging_enabled" {
  description = "Whether to enable logging"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket for logs"
  type        = string
  default     = ""
}

variable "logging_prefix" {
  description = "Prefix for log files"
  type        = string
  default     = ""
}

variable "logging_include_cookies" {
  description = "Include cookies in logs"
  type        = bool
  default     = false
}

variable "custom_error_responses" {
  description = "List of custom error responses"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number)
  }))
  default = []
}

variable "origin_access_controls" {
  description = "Map of origin access controls"
  type = map(object({
    description      = optional(string)
    origin_type      = optional(string)
    signing_behavior = optional(string)
    signing_protocol = optional(string)
  }))
  default = {}
}

variable "cloudfront_functions" {
  description = "Map of CloudFront functions"
  type = map(object({
    runtime = optional(string)
    comment = optional(string)
    code    = string
    publish = optional(bool)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}