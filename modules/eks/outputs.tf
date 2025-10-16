output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.node.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS nodes"
  value       = aws_iam_role.node.arn
}

output "node_iam_role_name" {
  description = "IAM role name of the EKS nodes"
  value       = aws_iam_role.node.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].arn : null
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS"
  value       = try(replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", ""), null)
}

output "node_groups" {
  description = "Map of node group attributes"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      id               = v.id
      arn              = v.arn
      status           = v.status
      capacity_type    = v.capacity_type
      instance_types   = v.instance_types
    }
  }
}

output "fargate_profiles" {
  description = "Map of Fargate profile attributes"
  value = {
    for k, v in aws_eks_fargate_profile.main : k => {
      id     = v.id
      arn    = v.arn
      status = v.status
    }
  }
}

output "cluster_addons" {
  description = "Map of EKS cluster addon attributes"
  value = {
    for k, v in aws_eks_addon.main : k => {
      id            = v.id
      arn           = v.arn
      addon_version = v.addon_version
    }
  }
}
