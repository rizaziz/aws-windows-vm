resource "aws_route53_zone" "dns_zone" {
  name = "labs.com"
  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_zone" "reverse_dns" {
  name = "0.16.172.in-addr.info"
  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "private_record" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "satellite.${aws_route53_zone.dns_zone.name}"
  type    = "A"
  ttl     = 60
  records = [var.ip_addr]
}

resource "aws_route53_record" "reverse_private_record" {
  zone_id = aws_route53_zone.reverse_dns.zone_id
  name    = "10.${aws_route53_zone.reverse_dns.name}"
  type    = "PTR"
  ttl     = 60
  records = ["satellite.labs.com"]
}

resource "aws_route53_record" "dns" {
  count = length(var.ssh_details)
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.vm_name}-${count.index}.${data.aws_route53_zone.zone.name}"
  type    = "A"
  ttl     = 300
  records = [var.ssh_details[count.index].ip_addr]
}

resource "random_id" "trigger" {
  byte_length = 4
}

resource "null_resource" "ensure_ssh_folder" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "if [[ ! -d ${var.home_dir}/.ssh/config.d ]]; then mkdir -p ${var.home_dir}/.ssh; fi"
  }
}

resource "local_file" "ssh_config" {
  content  = "Include config.d/*"
  filename = "${var.home_dir}/.ssh/config"
  lifecycle {
    replace_triggered_by = [random_id.trigger.id]
  }
  depends_on = [null_resource.ensure_ssh_folder]
}


resource "local_file" "ssh_private_key" {
  count = length(var.ssh_details)
  content         = var.ssh_details[count.index].private_key
  filename        = "${var.home_dir}/.ssh/${var.vm_name}-${count.index}_id_rsa"
  file_permission = "0600"
  lifecycle {
    replace_triggered_by = [random_id.trigger.id]
  }
  depends_on = [null_resource.ensure_ssh_folder]
}

resource "local_file" "host_ssh_config" {
  count = length(var.ssh_details)
  content = <<-EOF
    Host ${var.vm_name}-${count.index} ${var.vm_name}-${count.index}.${data.aws_route53_zone.zone.name}
      HostName ${var.ssh_details[count.index].ip_addr}
      User ${var.vm_default_user}
      IdentityFile ${var.home_dir}/.ssh/${var.vm_name}-${count.index}_id_rsa
      Port 22
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  EOF
  filename = "${var.home_dir}/.ssh/config.d/${var.vm_name}-${count.index}-config"
  depends_on = [null_resource.ensure_ssh_folder]
}

resource "null_resource" "ensure_ansible_host_vars_folder" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "if [[ ! -d inventory/host_vars ]]; then mkdir -p inventory/host_vars; fi"
  }
}

resource "null_resource" "ensure_ansible_group_vars_folder" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "if [[ ! -d inventory/group_vars ]]; then mkdir -p inventory/group_vars; fi"
  }
}

resource "local_file" "host_vars" {
  count = length(var.ssh_details)
  content = <<-EOF
    ansible_host: ${var.ssh_details[count.index].ip_addr}
    ansible_connection: ssh
    ansible_user: ${var.vm_default_user}
    ansible_port: 22
    ansible_ssh_private_key_file: ${var.home_dir}/.ssh/${var.vm_name}-${count.index}_id_rsa
    ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  EOF
  filename = "inventory/host_vars/${var.vm_name}-${count.index}.${var.dns_zone}"
  depends_on = [ null_resource.ensure_ansible_host_vars_folder ]
  lifecycle {
    replace_triggered_by = [random_id.trigger.id]
  }
}

resource "local_file" "group_vars" {
  count = length(var.ssh_details)
  content = <<-EOF
    ansible_python_interpreter: /usr/bin/python3.9
  EOF
  filename = "inventory/group_vars/${var.vm_group}"
  depends_on = [ null_resource.ensure_ansible_group_vars_folder ]
  lifecycle {
    replace_triggered_by = [random_id.trigger.id]
  }
}

resource "local_file" "inventory" {
  content = yamlencode(local.inventory)
  filename = "inventory/hosts"
  lifecycle {
    replace_triggered_by = [random_id.trigger.id]
  }
}
