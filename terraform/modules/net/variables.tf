variable "labels" {
  description = "A map of labels to apply to contained resources."
  default     = {}
  type        = map(string)
}

variable "netconfig" {
  type = object({
    cidr    = string
    subnets = list(map(string))
  })
}

variable "has_internet_access" {
  type    = bool
  default = true
}
