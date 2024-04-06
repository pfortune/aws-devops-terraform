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