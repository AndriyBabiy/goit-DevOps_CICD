
# Terraform AWS Infrastructure

Infrastructure as Code (IaC) project using Terraform to provision AWS resources
including VPC networking, S3 state management, and ECR container registry.

## Project Structure

```
lesson-5/
│
├── backend.tf                 # Remote state backend configuration (S3 + DynamoDB)
├── main.tf                    # Root module - providers and module calls
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output value definitions
│
└── modules/
    │
    ├── s3-backend/            # Terraform state management module
    │   ├── main.tf            # S3 bucket and DynamoDB table resources
    │   ├── variables.tf       # Module input variables
    │   └── outputs.tf         # Module outputs (bucket name, table name)
    │
    ├── vpc/                   # Network infrastructure module
    │   ├── main.tf            # VPC, subnets, gateways, route tables
    │   ├── variables.tf       # CIDR blocks, AZs, feature flags
    │   └── outputs.tf         # VPC ID, subnet IDs, gateway IDs
    │
    └── ecr/                   # Container registry module
        ├── main.tf            # ECR repository and lifecycle policy
        ├── variables.tf       # Repository name, scan settings
        └── outputs.tf         # Repository URL, ARN
```

## Modules

### S3 Backend Module
Creates S3 bucket and DynamoDB table for Terraform state management.

| Resource | Purpose |
|----------|---------|
| S3 Bucket | Stores terraform.tfstate file with versioning |
| DynamoDB Table | Provides state locking to prevent concurrent modifications |

### VPC Module
Creates a complete network infrastructure across multiple availability zones.

| Resource | Purpose |
|----------|---------|
| VPC | Isolated network with 10.0.0.0/16 CIDR |
| Public Subnets (x3) | For load balancers, bastion hosts (auto-assign public IP) |
| Private Subnets (x3) | For application servers, databases (no public IP) |
| Internet Gateway | Enables internet access for public subnets |
| NAT Gateway | Enables outbound internet for private subnets |
| Route Tables | Controls traffic routing for each subnet type |

### ECR Module
Creates Elastic Container Registry for Docker images.

| Resource | Purpose |
|----------|---------|
| ECR Repository | Stores Docker images with vulnerability scanning |
| Lifecycle Policy | Automatically removes old images (keeps last 10) |

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with valid credentials
- AWS account with appropriate IAM permissions

## Usage

Initialize Terraform (download providers and modules):
    ```terraform init```

Preview infrastructure changes:
    ```terraform plan```

Create infrastructure:
    ```terraform apply```

Destroy infrastructure (important - avoid AWS charges!):
    ```terraform destroy```

## Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| aws_region | AWS region for resources | string | eu-central-1 |
| project_name | Project name for resource naming | string | goit-devops |
| environment | Environment (dev/staging/prod) | string | dev |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| ecr_repository_url | URL of the ECR repository |
| s3_bucket_name | Name of the S3 state bucket |
| dynamodb_table_name | Name of the DynamoDB lock table |

## Important Notes

⚠️ **Credentials:** Never store AWS credentials in code. Use `aws configure` or environment variables.

💰 **Costs:** Remember to run `terraform destroy` after testing to avoid AWS charges.
   NAT Gateways cost approximately $0.045/hour (~$32/month).

🔒 **State:** Terraform state may contain sensitive information. Keep it secure.
