# Bootstrap Module Configuration
# Creates S3 bucket and DynamoDB table for Terraform state management

# Include root configuration for provider generation
include "root" {
  path = find_in_parent_folders()
}

# Include environment configuration
include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

# Point to the Terraform module
terraform {
  source = "../../../terraform/bootstrap"
}

# Store bootstrap state locally (chicken-and-egg problem)
# Bootstrap creates the S3 bucket, so it can't use it for its own state
remote_state {
  backend = "local"
  
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Module inputs
inputs = {
  region       = include.env.locals.aws_region
  project_name = include.env.locals.project_name
  environment  = include.env.locals.environment
}
