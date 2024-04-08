# State Management

## Overview
The `state` directory manages the Terraform state for this project, ensuring state is stored securely and consistently with locking to prevent conflicts.

## Files
- `main.tf` - Configures the Terraform backend using AWS S3 and DynamoDB for state locking.
- `outputs.tf` - Defines outputs for the Terraform state management.
- `variables.tf` - Declares variables used in state management configurations.

## Setup
1. Update `variables.tf` with appropriate values.
2. Run `terraform init` to initialize the Terraform working directory and backend.
3. Apply the configuration with `terraform apply`.

## Best Practices
- Do not manually edit the state files.
- Use Terraform workspaces for managing different environments.
