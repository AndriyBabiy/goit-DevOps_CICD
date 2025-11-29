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

# EKS Module (NEW for lesson-7)
module "eks" {
  source = "./modules/eks"

  cluster_name        = "${var.project_name}-eks-${var.environment}"
  cluster_version     = "1.28"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids

  node_instance_types = ["t3.micro"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 3

  tags = {
    Purpose = "Kubernetes Cluster"
  }
}
