locals {
  rules = flatten([
    for rule in var.ingress_rules: [
      for ip in rule.src_ips: [
        for prt in rule.ports: {
          src_ip = ip
          port = length(split("/", prt)) == 2 ? split("/", prt)[0] : "-1"
          proto = length(split("/", prt)) == 2 ? split("/", prt)[1] : prt
        }
      ]
    ]
  ])
}

resource "aws_security_group" "sc" {
  name   = "allow-ssh-rdp-icmp"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rules" {
  count             = length(local.rules)
  security_group_id = aws_security_group.sc.id
  cidr_ipv4         = local.rules[count.index].src_ip
  from_port         = local.rules[count.index].port
  ip_protocol       = local.rules[count.index].proto
  to_port           = local.rules[count.index].port
}
