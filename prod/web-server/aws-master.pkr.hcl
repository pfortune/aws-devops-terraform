packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amazon_linux" {
  ami_name      = "Master-Web-Server-AMI-${local.timestamp}"
  instance_type = "t2.nano"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "*amzn2-ami-hvm-*-x86_64-ebs"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

build {
  sources = [
    "source.amazon-ebs.amazon_linux"
  ]

  provisioner "shell" {
    inline = [
      "set -e",
      "sudo yum update -y",
      "sudo yum install -y httpd || { echo 'Failed to install httpd'; exit 1; }",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd",
      "echo 'Hello World' | sudo tee /var/www/html/index.html",
      "sudo yum clean all"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
