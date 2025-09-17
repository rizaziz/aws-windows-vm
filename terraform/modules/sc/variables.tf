variable "vpc_id" {
  type = string
}

variable "ingress_rules" {
  type = list(object({
    src_ips = list(string)
    ports = list(string)
  }))
}
