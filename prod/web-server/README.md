# Production Environment

## Overview
The `web-server` directory contains Terraform configurations for deploying the production infrastructure on AWS, including networking, compute, and security resources. This setup uses custom AMIs built with Packer.

## Files
- `main.tf` - Defines the AWS resources and modules for the production environment.
- `outputs.tf` - Specifies output variables for the production environment.
- `variables.tf` - Contains variable declarations for customisation.
- `versions.tf` - Specifies the required Terraform and provider versions.
- `terraform.tfvars.example` - An example variables file to be copied and filled out as `terraform.tfvars`.
- `user_data.sh` - User data script for the EC2 instances.

In the `packer` directory:
- `aws-master.pkr.hcl` - Packer template to build the custom AMI used in Terraform.
- `buddyservice.service` - Systemd service file for the Buddy Service.
- `mem.sh` - Shell script with custom CloudWatch metrics.
- `variables.pkr.hcl` - Packer variables file.
- `secrets.auto.pkrvars.hcl.example` - Packer variables file with sensitive data.

## Setup
### Packer AMI Build
1. Ensure Packer is installed and configured correctly.
2. Run the following command to build the custom AMI:
`packer build aws-master.pkr.hcl`

This will output the AMI details to `manifest.json`, which Terraform will use.

### Terraform Deployment
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and update it with your specific values.
2. Run `terraform init` to prepare your working directory for other commands.
3. Execute `terraform plan` to review the changes that will be made using the AMI built with Packer.
4. Apply the configuration with `terraform apply`.

## Recommendations
- Review and adjust `variables.tf` according to your environment needs.
- Regularly update to the latest versions specified in `versions.tf`.
