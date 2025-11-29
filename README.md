# GoIT DevOps CI/CD Project

## Overview

This project demonstrates a complete GitOps-based CI/CD pipeline using:
- **Jenkins** for Continuous Integration (build, push, update Git)
- **ArgoCD** for Continuous Deployment (sync from Git to Kubernetes)
- **Amazon EKS** for Kubernetes cluster
- **Amazon ECR** for container registry
- **Terraform** for infrastructure as code
- **Helm** for Kubernetes package management
- **Kaniko** for rootless Docker builds in Kubernetes

## Architecture

```
Developer → Git Push → Jenkins CI → ECR → ArgoCD → EKS
                          │                   │
                          └── Updates Git ────┘
```

### CI/CD Pipeline Flow

1. Developer pushes code to Git
2. Jenkins pipeline triggers (manual or webhook)
3. Kaniko builds Docker image inside Kubernetes
4. Image pushed to ECR with build number tag
5. Jenkins updates image tag in `charts/django-app/values.yaml`
6. ArgoCD detects Git change (polls every 3 minutes)
7. ArgoCD syncs new configuration to EKS
8. Kubernetes performs rolling update of pods

## Project Structure

```
goit-DevOps_CICD/
├── main.tf                    # Terraform root module
├── backend.tf                 # S3 backend configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── Dockerfile                 # Django Docker image
├── Jenkinsfile                # CI pipeline definition
├── requirements.txt           # Python dependencies
├── manage.py                  # Django management
├── myproject/                 # Django application
│
├── modules/
│   ├── s3-backend/            # State management
│   ├── vpc/                   # Network infrastructure
│   ├── ecr/                   # Container registry
│   ├── eks/                   # Kubernetes cluster
│   ├── jenkins/               # Jenkins CI server (Helm)
│   └── argocd/                # ArgoCD GitOps (Helm)
│
├── charts/
│   └── django-app/            # Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── configmap.yaml
│           └── hpa.yaml
│
└── argocd/
    └── application.yaml       # ArgoCD application manifest
```

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0.0
- AWS CLI v2 configured
- kubectl installed
- Helm >= 3.0
- Docker (for local builds)
- Git

## Quick Start

### 1. Deploy Infrastructure

```bash
terraform init
terraform apply
```

**Note:** Full deployment takes ~20-25 minutes (EKS cluster creation is the longest part).

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region eu-central-1 --name goit-devops-eks-dev
```

### 3. Access Jenkins

```bash
# Get admin password (Jenkins Helm chart 5.x)
kubectl get secret jenkins -n jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d && echo

# Port forward
kubectl --namespace jenkins port-forward svc/jenkins 8080:8080
```

Access at: http://localhost:8080 (username: `admin`)

### 4. Access ArgoCD

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

# Port forward (use 8081 since Jenkins uses 8080)
kubectl port-forward svc/argocd-server -n argocd 8081:80
```

Access at: http://localhost:8081 (username: `admin`)

**Note:** Uses HTTP (port 80) because ArgoCD is configured with `server_insecure=true`.

### 5. Configure Jenkins Pipeline

1. Create GitHub Personal Access Token with `repo` scope
2. Add credentials in Jenkins: Manage Jenkins → Credentials → Add → Username with password
   - ID: `github-credentials`
   - Username: Your GitHub username
   - Password: Your GitHub PAT
3. Create Pipeline job pointing to your repo's `Jenkinsfile`

### 6. Configure ArgoCD Application

```bash
# Login to ArgoCD CLI
argocd login localhost:8081 --insecure --username admin --password <PASSWORD>

# Get ECR URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Create application with ECR URL override
argocd app create django-app \
    --repo https://github.com/<YOUR_USERNAME>/goit-DevOps_CICD.git \
    --path charts/django-app \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace default \
    --sync-policy automated \
    --auto-prune \
    --self-heal \
    --revision lesson-9 \
    --helm-set image.repository=$ECR_URL
```

## Components

| Component | Purpose |
|-----------|---------|
| EKS Cluster | Managed Kubernetes |
| ECR | Docker image registry |
| Jenkins | CI - builds images, pushes to ECR, updates Git |
| ArgoCD | CD - syncs Git state to Kubernetes |
| Kaniko | Rootless Docker builds inside Kubernetes |
| Deployment | Runs Django pods |
| Service | LoadBalancer for external access |
| ConfigMap | Environment variables |
| HPA | Auto-scales 2-5 pods based on load |

## Known Issues & Troubleshooting

### Jenkinsfile Pipeline Issues

The following bugs may occur when running the Jenkins pipeline:

| Issue | Symptom | Fix |
|-------|---------|-----|
| Container file sharing | `cat: /tmp/ecr-password: No such file` | Use `${WORKSPACE}` instead of `/tmp` - containers don't share `/tmp` |
| Base64 newline wrapping | `invalid character '\n' in string literal` | Add `| tr -d '\n'` after base64 command |
| ECR push denied | `ecr:InitiateLayerUpload action denied` | Change EKS node policy to `AmazonEC2ContainerRegistryPowerUser` |
| Git dubious ownership | `fatal: detected dubious ownership` | Add `git config --global --add safe.directory ${WORKSPACE}` |

### Resource Issues

- **t3.micro won't work** - Only supports 4 pods/node. Use t3.small minimum (11 pods/node)
- **Jenkins liveness probe timeout** - May restart during builds on resource-constrained nodes

## Cleanup

```bash
# Delete ArgoCD application first
argocd app delete django-app --cascade

# Or via kubectl
kubectl delete application django-app -n argocd

# Destroy infrastructure
terraform destroy
```

**Important:** Always delete ArgoCD application before `terraform destroy` to avoid orphaned resources.

