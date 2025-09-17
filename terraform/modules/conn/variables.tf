variable "dns_zone" {
  description = "Dns zone"
  type        = string
}

variable "vm_name" {
  description = "Name of the vm used for ssh and ansible"
  type        = string
}

variable "vm_group" {
  description = "Name of the group used for ansible"
  type        = string
}

variable "vm_default_user" {
  description = "EC2 default user"
  type        = string
}

variable "home_dir" {
  description = "Used for configuring ssh and inventory"
  type        = string
}

variable "ssh_details" {
  description = "The SSH details to connecto to the VMs"
  type = list(object({
    ip_addr = string
    private_key = string
  }))
}

variable "vpc_id" {
  type = string
}

variable "ip_addr" {
  type = string
}
