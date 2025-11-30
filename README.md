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
│   ├── argocd/                # ArgoCD GitOps (Helm)
│   └── rds/                   # Database (RDS/Aurora)
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
    --revision final_project \
    --helm-set image.repository=$ECR_URL
```

## Components

| Component | Purpose |
|-----------|---------|
| EKS Cluster | Managed Kubernetes |
| ECR | Docker image registry |
| RDS/Aurora | Managed database (PostgreSQL/MySQL) |
| Jenkins | CI - builds images, pushes to ECR, updates Git |
| ArgoCD | CD - syncs Git state to Kubernetes |
| Kaniko | Rootless Docker builds inside Kubernetes |
| Deployment | Runs Django pods |
| Service | LoadBalancer for external access |
| ConfigMap | Environment variables |
| HPA | Auto-scales 2-5 pods based on load |

---

## RDS Database Module

Universal Terraform module supporting both **Aurora Cluster** and **Standard RDS Instance**.

### Module Usage Example

```hcl
module "rds" {
  source = "./modules/rds"

  # General
  identifier = "my-app-db"
  use_aurora = false  # true = Aurora Cluster, false = RDS Instance

  # Network
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Engine
  engine         = "postgres"
  engine_version = "15.13"
  instance_class = "db.t3.micro"

  # Database
  database_name   = "myapp"
  master_username = "dbadmin"
  master_password = var.db_password

  # Security
  allowed_cidr_blocks = [module.vpc.vpc_cidr]

  # Parameter Group
  parameter_group_family = "postgres15"
}
```

### Variable Descriptions

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `identifier` | string | - | Unique identifier for all database resources |
| `use_aurora` | bool | `false` | `true` = Aurora Cluster, `false` = RDS Instance |
| `vpc_id` | string | - | VPC ID for security group |
| `subnet_ids` | list | - | Subnet IDs for DB subnet group (min 2 AZs) |
| `engine` | string | `"postgres"` | Engine: `postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql` |
| `engine_version` | string | `"15.13"` | Database engine version |
| `instance_class` | string | `"db.t3.micro"` | Instance size (Aurora requires `db.t3.medium`+) |
| `database_name` | string | - | Default database name |
| `master_username` | string | `"dbadmin"` | Master username |
| `master_password` | string | - | Master password (sensitive) |
| `port` | number | `5432` | Database port (3306 for MySQL) |
| `multi_az` | bool | `false` | Multi-AZ deployment (RDS only) |
| `aurora_instance_count` | number | `2` | Aurora instances (1 writer + N-1 readers) |
| `parameter_group_family` | string | `"postgres15"` | Must match engine version |

### Changing Database Configuration

#### Switch Between RDS and Aurora

```hcl
# Standard RDS Instance
use_aurora = false
engine     = "postgres"

# Aurora Cluster
use_aurora = true
engine     = "aurora-postgresql"
```

> **Warning:** Changing `use_aurora` destroys and recreates the database!

#### Change Database Engine

```hcl
# PostgreSQL (default)
engine                 = "postgres"
port                   = 5432
parameter_group_family = "postgres15"

# MySQL
engine                 = "mysql"
port                   = 3306
parameter_group_family = "mysql8.0"
```

#### Change Instance Class

```hcl
instance_class = "db.t3.micro"   # Development
instance_class = "db.t3.medium"  # Production (required for Aurora)
instance_class = "db.r6g.large"  # High-performance
```

#### Enable High Availability

```hcl
# RDS Instance
multi_az = true

# Aurora
aurora_instance_count = 3  # 1 writer + 2 readers
```

---

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

### Jenkins Deployment Issues

| Issue | Symptom | Fix |
|-------|---------|-----|
| Helm timeout | `context deadline exceeded` during terraform apply | Set `wait = false` in `modules/jenkins/main.tf` |
| PVC stuck Pending | Jenkins pod stuck in Pending, PVC not bound | Disable persistence (`enabled = false`) - EBS CSI driver not installed |
| Pod not recreating | Config changes not applied after helm update | Delete pod manually: `kubectl delete pod jenkins-0 -n jenkins` |

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

