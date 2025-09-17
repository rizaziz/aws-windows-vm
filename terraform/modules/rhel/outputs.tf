output "private_key_ssh" {
  value     = tls_private_key.private-key.private_key_openssh
  sensitive = true
}

output "public_key_openssh" {
  value     = tls_private_key.private-key.public_key_openssh
  sensitive = false
}

output "private_key" {
  value     = tls_private_key.private-key.private_key_pem
  sensitive = true
}

output "public_ip_addr" {
  value = aws_instance.rhel.public_ip
}

output "connection_details" {
  value = {
    ip_addr = aws_instance.rhel.public_ip
    private_key = tls_private_key.private-key.private_key_openssh
  }
}
