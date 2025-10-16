output "raw_data_bucket" {
  description = "Raw data bucket"
  value       = module.raw_data_bucket.bucket_id
}

output "processed_data_bucket" {
  description = "Processed data bucket"
  value       = module.processed_data_bucket.bucket_id
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = module.rds.db_instance_endpoint
}

output "coordinator_instance_id" {
  description = "Coordinator instance ID"
  value       = module.coordinator.instance_id
}
