terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC + public subnets
module "vpc" {
  source = "../../modules/vpc"

  name   = "${var.app_name}-dev"
  cidr   = "10.0.0.0/16"
  azs    = ["${var.aws_region}a", "${var.aws_region}b"]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

# ASG + ALB + CPU scaling
module "asg_app" {
  source = "../../modules/asg_app"

  app_name          = "${var.app_name}-dev"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  ami_id            = var.app_ami_id

  instance_type    = var.instance_type
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size
}
