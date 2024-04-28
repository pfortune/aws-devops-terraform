variable "db_address" {
  type        = string
  description = "The address of the MongoDB server."
}

variable "cloudinary_key" {
  type        = string
  description = "The Cloudinary API key."
}

variable "cloudinary_secret" {
  type        = string
  description = "The Cloudinary API secret."
  sensitive   = true
}

variable "cloudinary_name" {
  type        = string
  description = "The Cloudinary cloud name."
}

variable "cookie_password" {
  type        = string
  sensitive   = true
  description = "Cookie password for the application."
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}