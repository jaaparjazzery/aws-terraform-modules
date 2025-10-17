# modules/apigateway/outputs.tf

output "api_id" {
  description = "ID of the API Gateway"
  value       = var.api_type == "REST" ? aws_api_gateway_rest_api.this[0].id : aws_apigatewayv2_api.this[0].id
}

output "api_arn" {
  description = "ARN of the API Gateway"
  value       = var.api_type == "REST" ? aws_api_gateway_rest_api.this[0].arn : aws_apigatewayv2_api.this[0].arn
}

output "api_endpoint" {
  description = "Endpoint URL of the API Gateway"
  value       = var.api_type == "REST" ? aws_api_gateway_deployment.this[0].invoke_url : aws_apigatewayv2_api.this[0].api_endpoint
}

output "stage_arn" {
  description = "ARN of the API Gateway stage"
  value       = var.api_type == "REST" ? aws_api_gateway_stage.this[0].arn : aws_apigatewayv2_stage.this[0].arn
}

output "stage_invoke_url" {
  description = "Invoke URL of the API Gateway stage"
  value       = var.api_type == "REST" ? aws_api_gateway_stage.this[0].invoke_url : aws_apigatewayv2_stage.this[0].invoke_url
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = var.api_type == "REST" ? aws_api_gateway_rest_api.this[0].execution_arn : aws_apigatewayv2_api.this[0].execution_arn
}

output "domain_name" {
  description = "Custom domain name"
  value       = var.domain_name != null ? (var.api_type == "REST" ? aws_api_gateway_domain_name.rest[0].cloudfront_domain_name : aws_apigatewayv2_domain_name.http[0].domain_name_configuration[0].target_domain_name) : null
}

output "domain_hosted_zone_id" {
  description = "Hosted zone ID of the custom domain"
  value       = var.domain_name != null ? (var.api_type == "REST" ? aws_api_gateway_domain_name.rest[0].cloudfront_zone_id : aws_apigatewayv2_domain_name.http[0].domain_name_configuration[0].hosted_zone_id) : null
}

output "usage_plan_ids" {
  description = "Map of usage plan names to IDs"
  value       = { for k, v in aws_api_gateway_usage_plan.this : k => v.id }
}

output "api_key_ids" {
  description = "Map of API key names to IDs"
  value       = { for k, v in aws_api_gateway_api_key.this : k => v.id }
}

output "api_key_values" {
  description = "Map of API key names to values"
  value       = { for k, v in aws_api_gateway_api_key.this : k => v.value }
  sensitive   = true
}