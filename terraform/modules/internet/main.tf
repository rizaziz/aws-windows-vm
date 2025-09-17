resource "aws_security_group" "sc" {
  name   = "internet-access"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "allow-to-internet" {
  security_group_id = aws_security_group.sc.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id
  tags = {
    Name = "Dev"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = var.vpc_id
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
  subnet_id      = var.subnet_id
  route_table_id = aws_route_table.rt.id
}
