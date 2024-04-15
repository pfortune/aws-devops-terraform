# devops-aws-terraform

## Overview
This repository contains Terraform configurations for deploying and managing infrastructure on AWS. It incorporates Packer for building custom AMIs and is structured into separate directories for production infrastructure and state management.

## Directory Structure

- `/prod` - Contains Terraform configurations for the production environment, utilising custom AMIs built with Packer.
- `/global/s3` - Manages the initial setup and ongoing management of Terraform state using AWS S3 and DynamoDB.

## Prerequisites
- Terraform >= 1.0.0
- Packer >= 1.7.0
- AWS CLI configured with Administrator access
- An active AWS account

## Getting Started
1. Clone the repository to your local machine.
2. Begin by navigating to the `/global/s3` directory to set up and initialise the Terraform backend. This setup is essential for secure and efficient management of Terraform state.
3. Follow the README.md in the `/global/s3` directory for detailed instructions on setting up the backend.
4. Once the backend is configured, proceed to the `/prod` directory to manage the production environment. Ensure you are using the AMIs built with Packer.
5. Refer to the README.md in the `/prod` directory for comprehensive guidance on deploying and managing the production infrastructure.
