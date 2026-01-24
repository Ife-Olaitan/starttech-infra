terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "Starttech Infrastructure"
    }
  }
}

module "storage" {
  source      = "./modules/storage"
  bucket_name = "${var.name}-frontend"
  oac_name    = "${var.name}-oac"
  name        = var.name
}

module "networking" {
  source               = "./modules/networking"
  name                 = var.name
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
}

module "compute" {
  source             = "./modules/compute"
  instance_type      = var.instance_type
  name               = var.name
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  vpc_id             = module.networking.vpc_id
  log_group_name     = module.monitoring.log_group_name
}

module "monitoring" {
  source = "./modules/monitoring"
  name   = var.name
}
