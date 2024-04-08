# Production Environment

## Overview
The `prod` directory contains Terraform configurations for deploying the production infrastructure on AWS, including networking, compute, and security resources.

## Files
- `main.tf` - Defines the AWS resources and modules for the production environment.
- `outputs.tf` - Specifies output variables for the production environment.
- `variables.tf` - Contains variable declarations for customization.
- `versions.tf` - Specifies the required Terraform and provider versions.
- `terraform.tfvars.example` - An example variables file to be copied and filled out as `terraform.tfvars`.

## Setup
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and update it with your specific values.
2. Run `terraform init` to prepare your working directory for other commands.
3. Execute `terraform plan` to review the changes that will be made.
4. Apply the configuration with `terraform apply`.

## Recommendations
- Review and adjust `variables.tf` according to your environment needs.
- Regularly update to the latest versions specified in `versions.tf`.
