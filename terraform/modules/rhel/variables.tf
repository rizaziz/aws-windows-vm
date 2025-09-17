variable "subnet_id" {
  description = "The subnet the vm is created in"
  type        = string
}

variable "ami" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "security_group_ids" {
  description = "The Security Group Id used for network interface"
  type = list(string)
}

variable "disk_size" {
  description = "The size of the disk in Gigabytes"
  type = number
}

variable "private_ip" {
  type = string
}
