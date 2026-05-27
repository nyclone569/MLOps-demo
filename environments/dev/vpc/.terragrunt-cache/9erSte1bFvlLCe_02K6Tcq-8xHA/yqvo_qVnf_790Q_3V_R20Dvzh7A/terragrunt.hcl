# VPC Module Configuration
# Creates VPC with public, private, and isolated subnets

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Include environment configuration
include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

# Dependency: VPC needs bootstrap to be created first (for remote state)
dependency "bootstrap" {
  config_path = "../bootstrap"
  
  # Mock outputs for plan/validate commands (when bootstrap doesn't exist yet)
  mock_outputs = {
    s3_bucket_name      = "mock-bucket"
    dynamodb_table_name = "mock-table"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
  
  # Don't fail if bootstrap outputs are not available during plan
  skip_outputs = false
}

# Point to the Terraform module
terraform {
  source = "../../../terraform/vpc"
}

# Module inputs
inputs = {
  region             = include.env.locals.aws_region
  project_name       = include.env.locals.project_name
  environment        = include.env.locals.environment
  vpc_cidr           = include.env.locals.vpc_cidr
  single_nat_gateway = include.env.locals.single_nat_gateway
  
  # Optional: Add more VPC-specific configurations
  enable_nat_gateway   = include.env.locals.enable_nat_gateway
  enable_dns_hostnames = include.env.locals.enable_dns_hostnames
  enable_dns_support   = include.env.locals.enable_dns_support
  
  # Tags
  tags = include.env.locals.common_tags
}
