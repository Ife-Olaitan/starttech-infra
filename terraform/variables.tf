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

# GitHub OIDC
variable "github_repo" {
  description = "GitHub repository in format 'owner/repo-name'"
  type        = string
}

variable "dockerhub_image" {
  description = "Docker Hub image name"
  type        = string
}

variable "mongo_uri" {
  description = "MongoDB Atlas connection string"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}