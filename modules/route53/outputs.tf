# modules/route53/outputs.tf

output "zone_ids" {
  description = "Map of hosted zone names to zone IDs"
  value       = { for k, v in aws_route53_zone.this : k => v.zone_id }
}

output "zone_name_servers" {
  description = "Map of hosted zone names to name servers"
  value       = { for k, v in aws_route53_zone.this : k => v.name_servers }
}

output "health_check_ids" {
  description = "Map of health check names to IDs"
  value       = { for k, v in aws_route53_health_check.this : k => v.id }
}

output "delegation_set_name_servers" {
  description = "Map of delegation set names to name servers"
  value       = { for k, v in aws_route53_delegation_set.this : k => v.name_servers }
}