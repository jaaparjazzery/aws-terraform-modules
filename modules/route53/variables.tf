# modules/route53/variables.tf

variable "hosted_zones" {
  description = "Map of hosted zones to create"
  type = map(object({
    comment           = optional(string)
    force_destroy     = optional(bool)
    delegation_set_id = optional(string)
    vpcs = optional(list(object({
      vpc_id     = string
      vpc_region = optional(string)
    })))
  }))
  default = {}
}

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    zone_name         = string
    name              = string
    type              = string
    ttl               = optional(number)
    records           = optional(list(string))
    set_identifier    = optional(string)
    health_check_id   = optional(string)
    multivalue_answer_routing_policy = optional(bool)
    allow_overwrite   = optional(bool)
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool)
    }))
    weighted_routing_policy = optional(object({
      weight = number
    }))
    latency_routing_policy = optional(object({
      region = string
    }))
    geolocation_routing_policy = optional(object({
      continent   = optional(string)
      country     = optional(string)
      subdivision = optional(string)
    }))
    failover_routing_policy = optional(object({
      type = string
    }))
    cidr_routing_policy = optional(object({
      collection_id = string
      location_name = string
    }))
  }))
  default = {}
}

variable "health_checks" {
  description = "Map of health checks to create"
  type = map(object({
    type                            = string
    ip_address                      = optional(string)
    port                            = optional(number)
    resource_path                   = optional(string)
    fqdn                            = optional(string)
    request_interval                = optional(number)
    failure_threshold               = optional(number)
    measure_latency                 = optional(bool)
    invert_healthcheck              = optional(bool)
    disabled                        = optional(bool)
    enable_sni                      = optional(bool)
    child_healthchecks              = optional(list(string))
    child_health_threshold          = optional(number)
    cloudwatch_alarm_name           = optional(string)
    cloudwatch_alarm_region         = optional(string)
    insufficient_data_health_status = optional(string)
    reference_name                  = optional(string)
    search_string                   = optional(string)
  }))
  default = {}
}

variable "query_logs" {
  description = "Map of query logging configurations"
  type = map(object({
    cloudwatch_log_group_arn = string
  }))
  default = {}
}

variable "traffic_policies" {
  description = "Map of traffic policies to create"
  type = map(object({
    comment  = optional(string)
    document = string
  }))
  default = {}
}

variable "traffic_policy_instances" {
  description = "Map of traffic policy instances to create"
  type = map(object({
    name                   = string
    traffic_policy_name    = string
    traffic_policy_version = number
    zone_name              = string
    ttl                    = number
  }))
  default = {}
}

variable "delegation_sets" {
  description = "Map of delegation sets to create"
  type        = map(object({}))
  default     = {}
}

variable "vpc_association_authorizations" {
  description = "Map of VPC association authorizations"
  type = map(object({
    zone_name = string
    vpc_id    = string
  }))
  default = {}
}

variable "zone_associations" {
  description = "Map of zone associations"
  type = map(object({
    zone_name = string
    vpc_id    = string
  }))
  default = {}
}

variable "create_health_check_alarms" {
  description = "Whether to create CloudWatch alarms for health checks"
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