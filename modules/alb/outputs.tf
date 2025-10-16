output "alb_id" {
  description = "ID of the ALB"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.main.zone_id
}

output "target_group_arns" {
  description = "ARNs of target groups"
  value       = { for k, v in aws_lb_target_group.main : k => v.arn }
}

output "target_group_names" {
  description = "Names of target groups"
  value       = { for k, v in aws_lb_target_group.main : k => v.name }
}

output "http_listener_arn" {
  description = "ARN of HTTP listener"
  value       = var.enable_http_listener ? aws_lb_listener.http[0].arn : null
}

output "https_listener_arn" {
  description = "ARN of HTTPS listener"
  value       = var.enable_https_listener ? aws_lb_listener.https[0].arn : null
}
