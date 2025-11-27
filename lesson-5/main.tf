# Configure AWS Provider
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# S3 Backend Module
module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name         = "${var.project_name}-terraform-state-${var.environment}"
  dynamodb_table_name = "terraform-locks"

  tags = {
    Purpose = "Terraform State"
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "${var.project_name}-vpc-${var.environment}"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  enable_nat_gateway = true

  tags = {
    Purpose = "Main VPC"
  }
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  repository_name = "${var.project_name}-app"
  scan_on_push    = true

  tags = {
    Purpose = "Application Images"
  }
}
