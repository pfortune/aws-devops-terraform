# Configure the AWS Provider with the specified region from variables
provider "aws" {
  region = var.region
}

# Create a VPC using the terraform-aws-modules/vpc/aws module
# with specified CIDR, availability zones, and subnet configurations.
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "devops-vpc"  # Name of the VPC
  cidr = "10.0.0.0/16" # CIDR block for the VPC

  # Availability zones and corresponding subnet configurations
  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # Enabling NAT gateway, VPN gateway, and DNS hostnames for the VPC
  enable_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true

  # Tags to be applied to all resources created by the module
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "aws_ami" "latest_master_web_server" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Master-Web-Server-AMI-*"]
  }

  owners = ["self"] 
}

# Security group for instances, allowing inbound TCP traffic on the server port
resource "aws_security_group" "instance" {
  name   = "${var.prefix}-instance"
  vpc_id = module.vpc.vpc_id # Associate with the VPC created above

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch configuration for instances, including user data for initial setup
resource "aws_launch_configuration" "server" {
  image_id        = data.aws_ami.latest_master_web_server.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

  lifecycle {
    create_before_destroy = true # Ensure replacement instances are created before the old ones are destroyed
  }
}

# Auto Scaling Group configuration, targeting the private subnets of the VPC
resource "aws_autoscaling_group" "server" {
  launch_configuration = aws_launch_configuration.server.name
  vpc_zone_identifier  = module.vpc.private_subnets # Use private subnets for the ASG

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 5

  tag {
    key                 = "Name"
    value               = "${var.prefix}-asg-server"
    propagate_at_launch = true # Ensure tags are propagated to instances launched by the ASG
  }
}

# Application Load Balancer setup, associated with public subnets of the VPC
resource "aws_lb" "server" {
  name               = "terraform-asg-server"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets # Place the ALB in public subnets for external access
  security_groups    = [aws_security_group.alb.id]
}

# Listener for the ALB, directing HTTP traffic
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.server.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# Security group for the ALB, allowing inbound HTTP traffic and unrestricted outbound traffic
resource "aws_security_group" "alb" {
  name   = "${var.prefix}-server-alb"
  vpc_id = module.vpc.vpc_id # Associate with the created VPC

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target group for the ASG instances, with health check configurations
resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-server"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener rule for the ALB, forwarding all traffic to the ASG target group
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}