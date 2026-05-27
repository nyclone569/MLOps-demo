# Root Terragrunt Configuration
# This file contains common configuration shared across all environments

locals {
  # Parse the file path to extract environment and module information
  # Expected path: .../environments/{env}/{module}/...
  path_parts = split("/", get_terragrunt_dir())
  
  # Find the index of "environments" in the path
  env_index = index(local.path_parts, "environments")
  
  # Extract environment and module names
  environment = local.env_index >= 0 ? local.path_parts[local.env_index + 1] : "dev"
  module_name = local.env_index >= 0 ? local.path_parts[local.env_index + 2] : "unknown"
  
  # Default AWS region (can be overridden in env.hcl)
  aws_region = "ap-southeast-1"
}

# Configure remote state storage in S3
remote_state {
  backend = "s3"
  
  config = {
    encrypt        = true
    bucket         = "dev-vsf-tts"
    key            = "${local.environment}/${local.module_name}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = "dev-vsf-tts-lock"
    
    # Enable bucket versioning for state history
    s3_bucket_tags = {
      Name        = "Terraform State Storage"
      Environment = local.environment
      ManagedBy   = "Terragrunt"
    }
    
    dynamodb_table_tags = {
      Name        = "Terraform Lock Table"
      Environment = local.environment
      ManagedBy   = "Terragrunt"
    }
  }
  
  # Generate backend configuration file
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate AWS provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"
  
  default_tags {
    tags = {
      Environment = "${local.environment}"
      ManagedBy   = "Terragrunt"
      Project     = "dev-vsf-tts"
    }
  }
}
EOF
}

# Terraform configuration
terraform {
  # Extra arguments for all commands that need vars
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
  }
  
  # Retry on lock timeout
  extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()
    
    arguments = [
      "-lock-timeout=20m"
    ]
  }
  
  # Auto-approve for destroy (optional, remove if you want confirmation)
  # extra_arguments "auto_approve" {
  #   commands = ["destroy"]
  #   arguments = ["-auto-approve"]
  # }
}

# Note: retryable_errors is not supported in Terragrunt v1.0+
# Terraform will automatically retry on transient errors

