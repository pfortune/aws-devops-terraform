provider "aws" {
  region = "us-east-1"
}

/* ===================================================================
   Local Variables Definition
   =================================================================== */
# Define commonly used port numbers and IP ranges as local variables
locals {
  db_port      = 27017
  http_port    = 80
  ssh_port     = 22
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

/* ===================================================================
   AMI Data Fetching
   =================================================================== */
# Retrieve the latest AMI for the master web server and Amazon Linux
data "aws_ami" "latest_master_db" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Master-DB-AMI-*"]
  }
  owners = ["self"]
}

/* ===================================================================
   Remote State Access
   =================================================================== */
# Configure access to the remote state in S3 for cross-referencing other infrastructure elements

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-state-devops-2024"
    key    = "prod/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

/* ===================================================================
   Security Group
   =================================================================== */

resource "aws_security_group" "mongo_sg" {
  name        = "mongo-security-group"
  description = "Security group for MongoDB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips # Assuming your app's security group exposes its CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
  }
}

output "mongo_sg_id" {
  value = aws_security_group.mongo_sg.id
}

/* ===================================================================
   EC2 Instance
   =================================================================== */
resource "aws_instance" "database" {
  ami           = data.aws_ami.latest_master_db.id
  instance_type = "t2.nano"

  subnet_id              = data.terraform_remote_state.vpc.outputs.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]

  tags = {
    Name = "MongoDB Server"
  }
}
