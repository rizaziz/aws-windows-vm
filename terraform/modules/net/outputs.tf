output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.net.id
}

output "subnet_ids" {
  description = "The ID of the subnet"
  value       = aws_subnet.subnets[*].id
}
