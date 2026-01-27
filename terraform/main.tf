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
  source                   = "./modules/storage"
  bucket_name              = "${var.name}-frontend"
  oac_name                 = "${var.name}-oac"
  name                     = var.name
  github_oidc_provider_arn = module.storage.github_actions_role_arn
  github_repo              = var.github_repo
}

module "networking" {
  source               = "./modules/networking"
  name                 = var.name
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
}

module "compute" {
  source                   = "./modules/compute"
  instance_type            = var.instance_type
  name                     = var.name
  private_subnet_ids       = module.networking.private_subnet_ids
  public_subnet_ids        = module.networking.public_subnet_ids
  vpc_id                   = module.networking.vpc_id
  log_group_name           = module.monitoring.log_group_name
  dockerhub_image          = var.dockerhub_image
  jwt_secret               = var.jwt_secret
  mongo_uri                = var.mongo_uri
  github_oidc_provider_arn = module.compute.github_actions_role_arn
  github_repo              = var.github_repo
}

module "monitoring" {
  source = "./modules/monitoring"
  name   = var.name
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
