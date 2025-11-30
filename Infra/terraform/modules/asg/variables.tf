variable "app_name" {
  description = "Application name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB and ASG"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (use free-tier-ish like t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 3
}

variable "app_port" {
  description = "Application port on instances"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP health check path for ALB"
  type        = string
  default     = "/actuator/health"
}

# 🔼 Scale out when CPU > threshold
variable "scale_out_cpu_threshold" {
  description = "CPU % threshold to scale out"
  type        = number
  default     = 60
}

# 🔽 Scale in when CPU < threshold
variable "scale_in_cpu_threshold" {
  description = "CPU % threshold to scale in"
  type        = number
  default     = 20
}

variable "scale_out_adjustment" {
  description = "How many instances to add when scaling out"
  type        = number
  default     = 1
}

variable "scale_in_adjustment" {
  description = "How many instances to remove when scaling in (negative)"
  type        = number
  default     = -1
}
