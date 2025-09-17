resource "aws_vpc" "net" {
  cidr_block = var.netconfig.cidr
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnets" {
  count                   = length(var.netconfig.subnets)
  vpc_id                  = aws_vpc.net.id
  cidr_block              = var.netconfig.subnets[count.index].cidr
  availability_zone       = var.netconfig.subnets[count.index].zone
  map_public_ip_on_launch = true
}
