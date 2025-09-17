locals {
  ec2_user = var.is_windows ? var.username : "ec2-user"
}

resource "aws_vpc" "net" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = "Dev"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.net.id
  cidr_block        = "172.16.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Dev"
  }
}

resource "tls_private_key" "private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "access-key" {
  key_name   = "dev"
  public_key = tls_private_key.private-key.public_key_openssh
}

resource "aws_security_group" "sc" {
  name   = "allow-ssh-rdp-icmp"
  vpc_id = aws_vpc.net.id
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.sc.id
  cidr_ipv4         = var.whitelisted_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-rdp" {
  security_group_id = aws_security_group.sc.id
  cidr_ipv4         = var.whitelisted_ip
  from_port         = 3389
  ip_protocol       = "tcp"
  to_port           = 3389
}

resource "aws_vpc_security_group_ingress_rule" "allow-winrm" {
  count             = var.is_windows ? 1 : 0
  security_group_id = aws_security_group.sc.id
  cidr_ipv4         = var.whitelisted_ip
  ip_protocol       = "tcp"
  from_port         = 5985
  to_port           = 5986
}

resource "aws_vpc_security_group_ingress_rule" "allow-icmp" {
  security_group_id = aws_security_group.sc.id
  cidr_ipv4         = var.whitelisted_ip
  ip_protocol       = "icmp"
  from_port         = "-1"
  to_port           = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow-to-internet" {
  security_group_id = aws_security_group.sc.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.net.id
  tags = {
    Name = "Dev"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.net.id
  tags = {
    Name = "Dev"
  }
}

resource "aws_route" "routetoigw" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_internet_gateway.igw]
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}


resource "aws_network_interface" "eni" {
  subnet_id       = aws_subnet.subnet.id
  security_groups = [aws_security_group.sc.id]
}

resource "aws_eip" "eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.eni.id
}

resource "aws_instance" "win" {
  count         = var.is_windows ? 1 : 0
  ami           = var.ami
  instance_type = var.instance_type
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }

  key_name          = aws_key_pair.access-key.id
  get_password_data = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  user_data = <<-EOF
    <powershell>
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    # if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    #     Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    #     New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    # } else {
    #     Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
    # }
    New-NetFirewallRule -DisplayName "Allow SSH from dev machine" -Direction Inbound -Protocol TCP -LocalPort 22 -RemoteAddress "${var.whitelisted_ip}" -Action Allow -Profile Any
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
    Add-Content -Force -Path $env:ProgramData\ssh\administrators_authorized_keys -Value '${tls_private_key.private-key.public_key_openssh}'
    icacls.exe "$env:ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
    
    secedit /export /cfg C:\secpol.cfg
    (Get-Content C:\secpol.cfg) -Replace 'PasswordComplexity = 1', 'PasswordComplexity = 0' | Out-File C:\secpol.cfg
    secedit /configure /db $Env:windir\security\new.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
    Remove-Item C:\secpol.cfg

    $NewPwd = ConvertTo-SecureString ${var.password} -AsPlainText -Force
    New-LocalUser -Name ${var.username} -Password $NewPwd -AccountNeverExpires -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member ${var.username}

    # Write-Output "Setting execution policy to RemoteSigned..." >> C:\install.log
    # Set-ExecutionPolicy RemoteSigned -Force 
    # $Retries = 0
    # $MaxRetries = 30

    # While ($true) {
    #     try {
    #         Invoke-Sqlcmd -ServerInstance "localhost" -Database "master" -Query "SELECT @@SERVERNAME"
    #         Invoke-Sqlcmd -ServerInstance "localhost" -Query "CREATE LOGIN admin WITH PASSWORD = 'admin', CHECK_POLICY=OFF" 
    #         Invoke-Sqlcmd -ServerInstance "localhost" -Query "CREATE DATABASE keycloak"
    #         Invoke-Sqlcmd -ServerInstance "localhost" -Query "ALTER SERVER ROLE sysadmin ADD MEMBER admin"
    #         Invoke-Sqlcmd -ServerInstance "localhost" -Query "EXECUTE xp_instance_regwrite N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'LoginMode', REG_DWORD, 2"
    #         break
    #     } catch {
    #         $Retries++
    #         if ($Retries -ge $MaxRetries) {
    #             Write-Output "Failed to connect to SQL Server after $MaxRetries attempts." -ForegroundColor Red >> C:\install.log
    #             exit 1
    #         }
    #         Write-Output "Failed to set execution policy. Retrying..." -ForegroundColor Yellow >> C:\install.log
    #         Write-Output "Error: $($_.Exception.Message)" >> C:\install.log
    #         Start-Sleep -Seconds 10
    #     } finally {
    #         Restart-Service -Name "MSSQLSERVER" -Force
    #     }
    # }

    # Write-Output "Execution policy set successfully." >> C:\install.log
    # Write-Output "Creating self-signed certificate..." >> C:\install.log
    # $cert = New-SelfSignedCertificate -Subject "CN=MyTestCert" -DnsName "localhost", "mytestdomain.com" -CertStoreLocation "Cert:\LocalMachine\My"
    # $pass = ConvertTo-SecureString "foobar" -AsPlainText -Force
    # Export-PfxCertificate -Cert $cert -FilePath "C:\MyTestCert.pfx" -Password $pass
    # Write-Output "Self-signed certificate created and exported." >> C:\install.log
    # Write-Output "1" >> C:\status
    </powershell>
    EOF

  user_data_replace_on_change = true
}



resource "aws_instance" "rhel" {
  count         = var.is_windows ? 0 : 1
  ami           = var.ami
  instance_type = var.instance_type
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }

  key_name = aws_key_pair.access-key.id

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }
}

resource "random_id" "trigger" {
  byte_length = 4
}

resource "local_file" "ssh-config" {
  content         = tls_private_key.private-key.private_key_openssh
  filename        = "id_rsa"
  file_permission = "0600"
  lifecycle {
    replace_triggered_by = [random_id.trigger.id]
  }
}

resource "local_file" "ssh-config-public" {
  content  = <<-EOF
    Host ${var.vm_name}
      HostName ${aws_eip.eip.public_ip}
      User ${local.ec2_user}
      IdentityFile ~/.ssh/id_rsa
      Port 22
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  EOF
  filename = "${path.module}/config"
  lifecycle {
    replace_triggered_by = [random_id.trigger.id]
  }
}

resource "local_file" "inventory" {
  content = yamlencode({
    all = {
      hosts = {
        "${var.vm_name}" = {
          ansible_host                 = aws_eip.eip.public_ip
          ansible_connection           = "ssh"
          ansible_user                 = "${local.ec2_user}"
          ansible_port                 = 22
          ansible_ssh_private_key_file = "~/.ssh/id_rsa"
          ansible_ssh_common_args      = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
        }
      }
    }
  })
  filename = "${path.module}/inventory.yml"
  lifecycle {
    replace_triggered_by = [random_id.trigger.id]
  }
}

data "aws_route53_zone" "zone" {
  name = "aws.rizaziz.com."
}

resource "aws_route53_record" "dns" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "rhel9.${data.aws_route53_zone.zone.name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.eip.public_ip]
}

# resource "aws_ec2_instance_state" "test" {
#   instance_id = aws_instance.dev.id
#   state       = var.vm-state
#   depends_on  = [aws_instance.dev]
# }
