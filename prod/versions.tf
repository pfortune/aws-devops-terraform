terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.44.0"
    }
  }

    backend "s3" {
    bucket = "terraform-state-devops-2024"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-state-lock-devops-2024"
    encrypt        = true
  }
}