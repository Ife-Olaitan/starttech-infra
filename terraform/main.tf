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

module "frontend" {
  source      = "./modules/storage"
  bucket_name = "${var.name}-frontend"
  oac_name    = "${var.name}-oac"
  name        = var.name
}
