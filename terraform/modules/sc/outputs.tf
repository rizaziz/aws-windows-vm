output "security_group_id" {
  description = "The Security Group applied to network interface"
  value       = aws_security_group.sc.id
}