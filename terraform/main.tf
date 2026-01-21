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
      Project = "Month One Assessment"
    }
  }
}

module "frontend" {
  source      = "./modules/storage"
  bucket_name = "starttech-frontend"
  oac_name    = "starttech-oac"
  tags        = { Name = "Starttech Frontend" }
}