terraform {
  backend "s3" {
    bucket = "terraform-state-devops-2024"
    key    = "prod/db/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-state-lock-devops-2024"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "database" {
  identifier_prefix   = "terraform-devops"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = "mydb"

  username = var.db_username
  password = var.db_password
}