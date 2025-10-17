# modules/lambda/outputs.tf

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = var.create_role ? aws_iam_role.lambda[0].arn : var.role_arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = var.create_role ? aws_iam_role.lambda[0].name : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda[0].name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda[0].arn : null
}

output "aliases" {
  description = "Map of Lambda alias names to their ARNs"
  value       = { for k, v in aws_lambda_alias.this : k => v.arn }
}