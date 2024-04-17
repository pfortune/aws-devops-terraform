/* ===================================================================
   AWS Provider Configuration
   =================================================================== */
# Configure the AWS Provider with the region specified in the Terraform variables
provider "aws" {
  region = var.region
}

/* ===================================================================
   Local Variables Definition
   =================================================================== */
# Define commonly used port numbers and IP ranges as local variables
locals {
  app_port     = 3000
  http_port    = 80
  ssh_port     = 22
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

/* ===================================================================
   VPC Configuration
   =================================================================== */
# Deploy a Virtual Private Cloud (VPC) with subnet definitions and internet gateways
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = "devops-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

/* ===================================================================
   Remote State Access
   =================================================================== */
# Configure access to the remote state in S3 for cross-referencing other infrastructure elements
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "terraform-state-devops-2024"
    key    = "prod/db/terraform.tfstate"
    region = "us-east-1"
  }
}

/* ===================================================================
   AMI Data Fetching
   =================================================================== */
# Retrieve the latest AMI for the master web server and Amazon Linux
data "aws_ami" "latest_master_web_server" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Master-Web-Server-AMI-*"]
  }
  owners = ["self"]
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

/* ===================================================================
   Bastion Host Configuration
   =================================================================== */
# Deploy a bastion host with a public IP address and set up security groups for remote access
module "bastion" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  name                        = "bastion host"
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.pem_key
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.ssh_security_group.security_group_id, module.egress_security_group.security_group_id]
  tags = merge({
    Bastion-Name = "bastion-host"
  })
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

/* ===================================================================
   Security Groups Configuration
   =================================================================== */
# Define and configure security groups for different purposes: egress, HTTP, and SSH access
module "egress_security_group" {
  source             = "terraform-aws-modules/security-group/aws"
  name               = "${var.prefix}-all-egress"
  description        = "Allow all egress"
  vpc_id             = module.vpc.vpc_id
  egress_cidr_blocks = local.all_ips
  egress_rules       = ["all-all"]
  tags = {
    Name = "${var.prefix}-egress_sg"
  }
}

module "http_security_group" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.prefix}-http"
  description         = "Allow all HTTP and HTTPS ingress"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = local.all_ips
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  tags = {
    Name = "${var.prefix}-http"
  }
}

module "ssh_security_group" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.prefix}-ssh"
  description         = "Allow all SSH ingress"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  ingress_rules       = ["ssh-tcp"]
  tags = {
    Name = "${var.prefix}-ssh"
  }
}

module "ssh_bastion_security_group" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.prefix}-ssh-bastion"
  description         = "Allow all SSH ingress from bastion"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["${module.bastion.private_ip}/32"]
  ingress_rules       = ["ssh-tcp"]
  tags = {
    Name = "${var.prefix}-ssh-bastion"
  }
}

/* ===================================================================
   Load Balancer Configuration
   =================================================================== */
# Configure an Application Load Balancer (ALB) and define the target group and listener for HTTP traffic
module "alb" {
  source                     = "terraform-aws-modules/alb/aws"
  name                       = "${var.prefix}-alb"
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false
  create_security_group      = false
  security_groups            = [module.http_security_group.security_group_id, module.egress_security_group.security_group_id]
  tags = {
    Name = "${var.prefix}-alb"
  }
}

resource "aws_lb_target_group" "target_group-http" {
  name        = "${var.prefix}-tg"
  port        = local.http_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = local.http_port
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 4
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "load_balancer-http" {
  load_balancer_arn = module.alb.arn
  port              = local.http_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group-http.arn
  }
}

/* ===================================================================
   Auto Scaling Configuration
   =================================================================== */
# Define the auto scaling group, attach it to the load balancer, and configure scaling policies
module "auto_scaling_group" {
  source                      = "terraform-aws-modules/autoscaling/aws"
  name                        = "${var.prefix}-asg"
  min_size                    = var.min_size
  max_size                    = var.max_size
  desired_capacity            = var.desired_capacity
  
  vpc_zone_identifier         = module.vpc.private_subnets
  target_group_arns           = [aws_lb_target_group.target_group-http.arn]
  health_check_type           = "ELB"
  health_check_grace_period   = 30

  launch_template_name        = "${var.prefix}-launch-template"
  launch_template_description = "Launch template for Board Buddy app"
  launch_template_version     = "$Latest"

  security_groups = [
    module.http_security_group.security_group_id,
    module.ssh_bastion_security_group.security_group_id,
    module.egress_security_group.security_group_id
  ]

  image_id          = data.aws_ami.latest_master_web_server.id
  instance_type     = var.instance_type
  user_data         = base64encode(var.user_data)
  key_name          = var.pem_key
  enable_monitoring = true
  tags = {
    Name = "${var.prefix}-asg"
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.prefix}-asg-scale-up"
  autoscaling_group_name = module.auto_scaling_group.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.prefix}-asg-scale-down"
  autoscaling_group_name = module.auto_scaling_group.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

/* ===================================================================
   CloudWatch Alarms for Scaling
   =================================================================== */
# Set up CloudWatch alarms to automate scaling actions based on CPU utilization
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "${var.prefix}-high-cpu-alarm"
  alarm_description   = "Scale up triggered when CPU utilization is above 70%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  dimensions = {
    "AutoScalingGroupName" = module.auto_scaling_group.autoscaling_group_name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_up.arn, aws_sns_topic.autoscaling_notifications.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "${var.prefix}-low-cpu-alarm"
  alarm_description   = "Scale down triggered when CPU utilization is below 25%"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 25
  dimensions = {
    "AutoScalingGroupName" = module.auto_scaling_group.autoscaling_group_name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_down.arn, aws_sns_topic.autoscaling_notifications.arn]
}

/* ===================================================================
   SNS Topic for Notifications
   =================================================================== */
# Set up an SNS topic for sending notifications about auto-scaling events
resource "aws_sns_topic" "autoscaling_notifications" {
  name = "autoscaling-notifications"
}

resource "aws_sns_topic_subscription" "autoscaling_notifications_subscription" {
  topic_arn = aws_sns_topic.autoscaling_notifications.arn
  protocol  = "email"
  endpoint  = var.email
}
