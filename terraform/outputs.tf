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

output "win_password" {
  value     = rsadecrypt(aws_instance.dev.password_data, tls_private_key.private-key.private_key_pem)
  sensitive = true
}

output "win_ip" {
  value = aws_eip.eip.public_ip
}

output "cmdkey" {
  value     = "cmdkey /add:TERMSRV/\"${aws_eip.eip.public_ip}\" /user:\"AW_2025_02\\Administrator\" /pass:\"${rsadecrypt(aws_instance.dev.password_data, tls_private_key.private-key.private_key_pem)}\""
  sensitive = true
}

output "rdp_command" {
  value = "mstsc /v:${aws_eip.eip.public_ip} /console"
}