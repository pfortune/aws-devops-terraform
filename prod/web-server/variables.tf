variable "region" {
  type        = string
  description = "The AWS region where resources will be created."
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type."
  default     = "t2.nano"
}

variable "ami_id" {
  type        = string
  description = "The AMI ID to use for the EC2 instances."
}

variable "servers" {
  type        = number
  description = "The number of instances to launch."
}

variable "app_port" {
  type        = number
  description = "The port the server will use for HTTP requests."
  default     = 3000
}

variable "pem_key" {
  type        = string
  description = "The name of the PEM key to use for EC2 instances."
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "The prefix to use for all resource names."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources."
  default     = {}
}

variable "user_data" {
  type        = string
  description = "The user data to apply to the EC2 instances."
  default     = ""
}

variable "email" {
  type        = string
  description = "The email address to notify when changes are applied."
}

variable "min_size" {
  type        = number
  description = "The minimum number of instances in the autoscaling group."
  default     = 1
}

variable "max_size" {
  type        = number
  description = "The maximum number of instances in the autoscaling group."
  default     = 3
}

variable "desired_capacity" {
  type        = number
  description = "The desired number of instances in the autoscaling group."
  default     = 2
}