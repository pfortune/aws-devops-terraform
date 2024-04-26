terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-devops-2024"
    key    = "prod/db/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-state-lock-devops-2024"
    encrypt        = true
  }
}