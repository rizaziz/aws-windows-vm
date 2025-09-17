resource "tls_private_key" "private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_id" "key_suffix" {
  byte_length = 4
}

resource "aws_key_pair" "access-key" {
  key_name   = "dev-${random_id.key_suffix.id}"
  public_key = tls_private_key.private-key.public_key_openssh
}

resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  private_ips = [var.private_ip]
  security_groups = var.security_group_ids
}

resource "aws_instance" "rhel" {
  ami           = var.ami
  instance_type = var.instance_type
  primary_network_interface {
    network_interface_id = aws_network_interface.eni.id
  }

  key_name = aws_key_pair.access-key.id

  root_block_device {
    volume_size = var.disk_size
    volume_type = "gp3"
  }
}
