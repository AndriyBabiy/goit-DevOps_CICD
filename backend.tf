# Uncomment after first apply when S3 bucket exists
# terraform {
#   backend "s3" {
#     bucket         = "goit-devops-terraform-state-dev"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "eu-central-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
