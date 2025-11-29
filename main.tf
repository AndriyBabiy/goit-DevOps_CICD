# Configure AWS Provider
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
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

  node_instance_types = ["t3.small"]  # t3.micro only supports 4 pods/node - not enough for Jenkins+ArgoCD
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 3

  tags = {
    Purpose = "Kubernetes Cluster"
  }
}

# Data source to get EKS cluster auth
data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# Kubernetes Provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm Provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Jenkins Module (NEW for lesson-9)
module "jenkins" {
  source = "./modules/jenkins"

  namespace      = "jenkins"
  release_name   = "jenkins"
  service_type   = "ClusterIP"  # Use port-forward to save on LoadBalancer costs

  # Reduced resources for t3.micro
  controller_resources = {
    requests_cpu    = "200m"
    requests_memory = "256Mi"
    limits_cpu      = "400m"
    limits_memory   = "512Mi"
  }

  # Plugin names without versions - Jenkins will resolve compatible versions
  install_plugins = [
    "kubernetes",
    "workflow-aggregator",
    "git",
    "configuration-as-code"
  ]

  tags = {
    Purpose = "CI Server"
  }

  depends_on = [module.eks]
}

# ArgoCD Module (NEW for lesson-9)
module "argocd" {
  source = "./modules/argocd"

  namespace           = "argocd"
  release_name        = "argocd"
  server_service_type = "ClusterIP"  # Use port-forward to save on LoadBalancer costs
  server_insecure     = true          # Disable TLS for demo

  tags = {
    Purpose = "GitOps CD"
  }

  depends_on = [module.eks]
}
