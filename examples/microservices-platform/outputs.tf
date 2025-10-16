output "eks_cluster_endpoint" {
  description = "EKS endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_id} --region ${var.aws_region}"
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = module.rds.db_instance_endpoint
}
