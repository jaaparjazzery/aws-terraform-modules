# modules/stepfunctions/outputs.tf

output "state_machine_id" {
  description = "ID of the Step Functions state machine"
  value       = aws_sfn_state_machine.this.id
}

output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.this.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.this.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = var.create_role ? aws_iam_role.sfn[0].arn : var.role_arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = var.create_role ? aws_iam_role.sfn[0].name : null
}