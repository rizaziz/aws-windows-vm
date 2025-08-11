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