# modules/messaging/outputs.tf

output "sns_topic_arns" {
  description = "Map of SNS topic names to ARNs"
  value       = { for k, v in aws_sns_topic.this : k => v.arn }
}

output "sns_topic_ids" {
  description = "Map of SNS topic names to IDs"
  value       = { for k, v in aws_sns_topic.this : k => v.id }
}

output "sqs_queue_arns" {
  description = "Map of SQS queue names to ARNs"
  value       = { for k, v in aws_sqs_queue.this : k => v.arn }
}

output "sqs_queue_urls" {
  description = "Map of SQS queue names to URLs"
  value       = { for k, v in aws_sqs_queue.this : k => v.url }
}

output "sqs_dlq_arns" {
  description = "Map of SQS DLQ names to ARNs"
  value       = { for k, v in aws_sqs_queue.dlq : k => v.arn }
}

output "sqs_dlq_urls" {
  description = "Map of SQS DLQ names to URLs"
  value       = { for k, v in aws_sqs_queue.dlq : k => v.url }
}