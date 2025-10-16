output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "ALB URL"
  value       = "http://${module.alb.alb_dns_name}"
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = module.rds.db_instance_endpoint
}

output "assets_bucket_name" {
  description = "Assets bucket"
  value       = module.assets_bucket.bucket_id
}
