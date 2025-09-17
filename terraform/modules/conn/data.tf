data "aws_route53_zone" "zone" {
  name = "${var.dns_zone}."
}

locals {
  dns_name = "${var.vm_name}.${data.aws_route53_zone.zone.name}"
  inventory = {
    all: {
      children: {
        "${var.vm_group}": {
          hosts: {
            for i in range(length(var.ssh_details)) : "${var.vm_name}-${i}.${var.dns_zone}" => ""
          }
        }
      }
    }
  }
}