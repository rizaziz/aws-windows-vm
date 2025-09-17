variable "whitelisted_ip" {
  default = "73.214.231.6/32"
  type    = string
}

variable "vm-state" {
  default = "running"
  type    = string
}

variable "ami" {
  description = "AMI ID for the instance"
  type        = string
  default     = "ami-09cb80360d5069de4"
}

variable "password" {
  description = "Password for the admin user"
  type        = string
  default     = "admin"
}

variable "username" {
  description = "Name of the admin user"
  type        = string
  default     = "admin"
}

variable "is_windows" {
  description = "Whether if the machine is windows"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "vm_name" {
  description = "Name of the vm used for ssh and ansible"
  type        = string
  default     = "rhel"
}