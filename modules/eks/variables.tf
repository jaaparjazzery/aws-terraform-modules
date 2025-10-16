variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "cloudwatch_log_kms_key_id" {
  description = "KMS key ID for CloudWatch Logs encryption"
  type        = string
  default     = null
}

variable "cluster_encryption_key_arn" {
  description = "KMS key ARN for cluster encryption"
  type        = string
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Enable AWS Systems Manager access for nodes"
  type        = bool
  default     = true
}

variable "node_groups" {
  description = "Map of EKS managed node group configurations"
  type = map(object({
    desired_size               = number
    max_size                   = number
    min_size                   = number
    instance_types             = list(string)
    capacity_type              = string
    disk_size                  = number
    ami_type                   = string
    kubernetes_version         = optional(string)
    max_unavailable_percentage = optional(number, 33)
    subnet_ids                 = optional(list(string))
    key_name                   = optional(string)
    source_security_group_ids  = optional(list(string))
    launch_template_id         = optional(string)
    launch_template_version    = optional(string)
    labels                     = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "cluster_addons" {
  description = "Map of EKS cluster addons"
  type = map(object({
    addon_version            = optional(string)
    resolve_conflicts        = optional(string, "OVERWRITE")
    service_account_role_arn = optional(string)
    preserve                 = optional(bool, true)
  }))
  default = {
    vpc-cni = {
      addon_version = null
    }
    coredns = {
      addon_version = null
    }
    kube-proxy = {
      addon_version = null
    }
  }
}

variable "fargate_profiles" {
  description = "Map of Fargate profile configurations"
  type = map(object({
    subnet_ids = list(string)
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
