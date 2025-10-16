output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.main.arn
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.main.public_ip
}

output "eip_public_ip" {
  description = "Elastic IP address (if created)"
  value       = var.create_eip ? aws_eip.main[0].public_ip : null
}

output "instance_state" {
  description = "State of the instance"
  value       = aws_instance.main.instance_state
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.main.ami
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.main.availability_zone
}

output "primary_network_interface_id" {
  description = "Primary network interface ID"
  value       = aws_instance.main.primary_network_interface_id
}
