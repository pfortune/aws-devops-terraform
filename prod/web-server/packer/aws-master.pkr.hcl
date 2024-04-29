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
      name                = "al2023-ami-2023.*-kernel-6.1-x86_64"
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

  provisioner "file" {
    source      = "buddyservice.service"
    destination = "/tmp/buddyservice.service"
  }

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y net-tools sysstat cronie cronie-anacron stress-ng git-all",
      "echo 'export AWS_DEFAULT_REGION=us-east-1' >> /etc/profile",
      "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash",
      "source /home/ec2-user/.bashrc",
      "nvm install 16",
      "sudo mkdir -p /var/www/boardbuddy",
      "sudo chown -R ec2-user:ec2-user /var/www/boardbuddy",
      "sudo -u ec2-user bash -c 'git clone https://github.com/pfortune/boardbuddy-hapi /var/www/boardbuddy'",
      "sudo -i -u ec2-user bash -c 'cd /var/www/boardbuddy && npm install'",
      "echo 'Setting up environment variables...'",
      "cd /var/www/boardbuddy",
      "echo 'cloudinary_key=${var.cloudinary_key}' >> .env",
      "echo 'cloudinary_name=${var.cloudinary_name}' >> .env",
      "echo 'cloudinary_secret=${var.cloudinary_secret}' >> .env",
      "echo 'COOKIE_NAME=boardbuddy' >> .env",
      "echo 'COOKIE_PASSWORD=${var.cookie_password}' >> .env",
      "echo 'DB=${var.db_address}' >> .env",
      "echo 'NODE_ENV=production' >> .env",
      "echo 'STORE_TYPE=mongo' >> .env",
      "sudo mv /tmp/mem.sh /home/ec2-user/mem.sh",
      "sudo chown ec2-user:ec2-user /home/ec2-user/mem.sh",
      "sudo chmod +x /home/ec2-user/mem.sh",
      "(crontab -u ec2-user -l 2>/dev/null; echo '*/1 * * * * /home/ec2-user/mem.sh') | crontab -u ec2-user -",
      "sudo mv /tmp/buddyservice.service /etc/systemd/system/boardbuddy.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable boardbuddy.service",
      "sudo systemctl start boardbuddy.service"
    ]
  }

  post-processor "manifest" {
    output = "../manifest.json"
  }
}