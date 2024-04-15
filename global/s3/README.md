# State Management

## Overview
This directory, `global/s3`, manages the Terraform state for our project, ensuring secure storage and state locking through AWS S3 and DynamoDB to prevent conflicts.

## Files
- `main.tf` - Begins without backend configuration to facilitate the creation of AWS resources.
- `outputs.tf` - Defines outputs that relate to state management.
- `variables.tf` - Contains variable declarations for state management configurations.

## Setup
### Initial Configuration
Before you begin, make sure the `main.tf` does not include the backend configuration. The initial content should look like this:
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.44.0"
    }
  }
}
```

1. Update `variables.tf` with the required values for your AWS resources.
2. Run `terraform init` to initialise the Terraform environment.
3. Run `terraform apply` to create the S3 bucket and DynamoDB table needed for state management.

### Integrating Backend Configuration
Once the S3 bucket and DynamoDB table are in place:
1. Add the backend configuration to your `main.tf` file:
    ```terraform
    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "5.44.0"
        }
      }
      backend "s3" {
        bucket         = "terraform-state-devops-2024"
        key            = "global/s3/terraform.tfstate"
        region         = "us-east-1"
        dynamodb_table = "terraform-state-lock-devops-2024"
        encrypt        = true
      }
    }
    ```
2. Run `terraform init` again to reinitialise the setup with the backend configuration. During this step, Terraform will prompt you to migrate the state to the S3 backend.
3. Confirm the migration to move the state file to the newly configured backend.

## Best Practices
- Never manually edit the state files.
