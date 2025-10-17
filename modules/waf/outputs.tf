# modules/waf/outputs.tf

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_capacity" {
  description = "Web ACL capacity units (WCU) used by this Web ACL"
  value       = aws_wafv2_web_acl.this.capacity
}

output "ip_set_arns" {
  description = "Map of IP set names to ARNs"
  value       = { for k, v in aws_wafv2_ip_set.this : k => v.arn }
}

output "regex_pattern_set_arns" {
  description = "Map of regex pattern set names to ARNs"
  value       = { for k, v in aws_wafv2_regex_pattern_set.this : k => v.arn }
}