# General
variable "name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

# Compute
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}