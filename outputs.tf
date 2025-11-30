# S3 Backend Outputs
output "s3_bucket_name" {
  description = "Terraform state bucket"
  value       = module.s3_backend.bucket_name
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# ECR Outputs
output "ecr_repository_url" {
  description = "ECR repository URL for Django image"
  value       = module.ecr.repository_url
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

# Helpful command outputs
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecr.repository_url}"
}

# Jenkins Outputs
output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = module.jenkins.namespace
}

output "jenkins_admin_password_command" {
  description = "Command to get Jenkins admin password"
  value       = module.jenkins.get_admin_password_command
}

output "jenkins_port_forward_command" {
  description = "Command to port-forward Jenkins"
  value       = module.jenkins.port_forward_command
}

# ArgoCD Outputs
output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = module.argocd.namespace
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = module.argocd.get_admin_password_command
}

output "argocd_port_forward_command" {
  description = "Command to port-forward ArgoCD"
  value       = module.argocd.port_forward_command
}

# =============================================================================
# DATABASE OUTPUTS
# =============================================================================

output "database_endpoint" {
  description = "Database connection endpoint"
  value       = module.rds.connection_endpoint
}

output "database_connection_string" {
  description = "Database connection string template"
  value       = module.rds.connection_string
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = module.rds.security_group_id
}