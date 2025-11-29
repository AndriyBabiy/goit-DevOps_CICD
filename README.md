# Kubernetes Deployment with Helm

Django application deployed to Amazon EKS using Helm charts.

## Architecture

This project deploys a Django application to Kubernetes with:
- EKS cluster for container orchestration
- ECR for Docker image storage
- Helm for application deployment
- HPA for auto-scaling (2-5 pods)

## Project Structure

```
goit-DevOps_CICD/              # Repository root
│
├── main.tf                    # Terraform root module
├── backend.tf                 # S3 backend configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── Dockerfile                 # Django Docker image
├── requirements.txt           # Python dependencies
├── manage.py                  # Django management
├── myproject/                 # Django application
│
├── modules/
│   ├── s3-backend/            # State management
│   ├── vpc/                   # Network infrastructure
│   ├── ecr/                   # Container registry
│   └── eks/                   # Kubernetes cluster
│
└── charts/
    └── django-app/            # Helm chart
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured
- kubectl installed
- Helm >= 3.0

## Deployment Steps

### 1. Deploy Infrastructure

    terraform init
    terraform apply

### 2. Configure kubectl

    aws eks update-kubeconfig --region eu-central-1 --name goit-devops-eks-dev

### 3. Push Docker Image to ECR

    # Login to ECR
    aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <ECR_URL>

    # Tag and push
    docker tag django-app:latest <ECR_URL>:latest
    docker push <ECR_URL>:latest

### 4. Deploy with Helm

    helm install django-app charts/django-app --set image.repository=<ECR_URL>

### 5. Verify Deployment

    kubectl get pods
    kubectl get services
    kubectl get hpa

## Cleanup

    # Remove Helm release
    helm uninstall django-app

    # Destroy infrastructure
    terraform destroy

## Components

| Component | Purpose |
|-----------|---------|
| EKS Cluster | Managed Kubernetes |
| ECR | Docker image registry |
| Deployment | Runs Django pods |
| Service | LoadBalancer for external access |
| ConfigMap | Environment variables |
| HPA | Auto-scales 2-5 pods based on load |
# Test CI
