variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "table_name" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
}

variable "region" {
  type        = string
  description = "The AWS region where resources will be created."
  default     = "us-east-1"
}