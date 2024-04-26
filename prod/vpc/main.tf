/* ===================================================================
   AWS Provider Configuration
   =================================================================== */
# Configure the AWS Provider with the region specified in the Terraform variables
provider "aws" {
  region = var.region
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