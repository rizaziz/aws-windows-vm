variable "whitelisted_ip" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "home_dir" {
  type = string
}

module "vpc" {
  source = "./../../modules/net"
  netconfig = {
    cidr = "172.16.0.0/16"
    subnets = [
      {
        cidr = "172.16.0.0/24"
        zone = "us-east-1a"
      }
    ]
  }
  has_internet_access = true
}

module "sc" {
  source = "./../../modules/sc"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      src_ips : [var.whitelisted_ip]
      ports : ["22/tcp", "443/tcp", "3389/tcp", "icmp"]
    }
  ]
}

module "internet" {
  source    = "./../../modules/internet"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.subnet_ids[0]
}

module "fleet" {
  count              = 1
  source             = "./../../modules/rhel"
  subnet_id          = module.vpc.subnet_ids[0]
  private_ip         = "172.16.0.10"
  security_group_ids = [module.sc.security_group_id, module.internet.sc_id]
  ami                = "ami-0dfc569a8686b9320"
  instance_type      = "c5n.2xlarge" # "t3.xlarge"
  disk_size          = 400
  depends_on         = [module.vpc, module.sc]
}

module "connection" {
  vpc_id          = module.vpc.vpc_id
  ip_addr         = "172.16.0.10"
  source          = "./../../modules/conn"
  dns_zone        = "aws.rizaziz.com"
  home_dir        = var.home_dir
  vm_default_user = "ec2-user"
  vm_name         = var.vm_name
  vm_group        = "aws_rhel"
  ssh_details     = module.fleet[*].connection_details
  depends_on      = [module.fleet]
}
