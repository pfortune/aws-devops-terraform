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

build {
  sources = [
    "source.amazon-ebs.amazon_linux"
  ]

  provisioner "file" {
    source      = "mem.sh"
    destination = "/tmp/mem.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd net-tools sysstat cronie cronie-anacron",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd",
      "echo 'Hello World' | sudo tee /var/www/html/index.html",
      "sudo yum clean al",
      "sudo mv /tmp/mem.sh /usr/local/bin/mem.sh",
      "sudo chmod +x /usr/local/bin/mem.sh",
      "(crontab -l 2>/dev/null; echo '*/1 * * * * /usr/local/bin/mem.sh') | crontab -"
    ]
  }

  post-processor "manifest" {
    output = "../manifest.json"
  }
}
