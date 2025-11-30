variable "name" {
  description = "Name prefix for the VPC"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability Zones to use"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks (one per AZ)"
  type        = list(string)
}
