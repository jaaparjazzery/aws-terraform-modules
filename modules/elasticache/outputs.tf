# modules/elasticache/outputs.tf

output "replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = var.engine == "redis" ? aws_elasticache_replication_group.redis[0].id : null
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group"
  value       = var.engine == "redis" ? aws_elasticache_replication_group.redis[0].arn : null
}

output "primary_endpoint_address" {
  description = "Address of the primary endpoint"
  value       = var.engine == "redis" ? aws_elasticache_replication_group.redis[0].primary_endpoint_address : null
}

output "reader_endpoint_address" {
  description = "Address of the reader endpoint"
  value       = var.engine == "redis" ? aws_elasticache_replication_group.redis[0].reader_endpoint_address : null
}

output "configuration_endpoint_address" {
  description = "Address of the configuration endpoint (Memcached)"
  value       = var.engine == "memcached" ? aws_elasticache_cluster.memcached[0].configuration_endpoint : null
}

output "cluster_address" {
  description = "DNS name of the cache cluster (Memcached)"
  value       = var.engine == "memcached" ? aws_elasticache_cluster.memcached[0].cluster_address : null
}

output "member_clusters" {
  description = "List of member cluster IDs"
  value       = var.engine == "redis" ? aws_elasticache_replication_group.redis[0].member_clusters : null
}