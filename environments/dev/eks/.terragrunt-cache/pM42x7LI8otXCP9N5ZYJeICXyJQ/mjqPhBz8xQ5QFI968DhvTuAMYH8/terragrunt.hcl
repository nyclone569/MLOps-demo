# EKS Module Configuration
# Creates EKS cluster with managed node groups and add-ons

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Include environment configuration
include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

# Dependency: EKS needs VPC to be created first
dependency "vpc" {
  config_path = "../vpc"
  
  # Mock outputs for plan/validate commands
  mock_outputs = {
    vpc_id             = "vpc-mock-12345"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
    public_subnet_ids  = ["subnet-mock-3", "subnet-mock-4"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
  
  skip_outputs = false
}

# Point to the Terraform module
terraform {
  source = "../../../terraform/eks"
  
  # Hooks for EKS-specific operations
  
  # After apply, configure kubectl automatically
  after_hook "configure_kubectl" {
    commands     = ["apply"]
    execute      = [
      "bash", "-c",
      "aws eks update-kubeconfig --region ${include.env.locals.aws_region} --name ${include.env.locals.project_name} || echo 'Failed to update kubeconfig, run manually: aws eks update-kubeconfig --region ${include.env.locals.aws_region} --name ${include.env.locals.project_name}'"
    ]
    run_on_error = false
  }
  
  # After apply, display cluster info
  after_hook "cluster_info" {
    commands     = ["apply"]
    execute      = [
      "bash", "-c",
      "echo '\n=== EKS Cluster Information ===' && kubectl cluster-info 2>/dev/null || echo 'Run: kubectl get nodes'"
    ]
    run_on_error = false
  }
}

# Module inputs
inputs = {
  region       = include.env.locals.aws_region
  project_name = include.env.locals.project_name
  environment  = include.env.locals.environment
  cluster_name = include.env.locals.project_name
  
  # Cluster configuration
  cluster_version                 = include.env.locals.cluster_version
  cluster_endpoint_public_access  = include.env.locals.cluster_endpoint_public_access
  cluster_endpoint_private_access = include.env.locals.cluster_endpoint_private_access
  
  # VPC inputs from dependency
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  
  # Node group configuration
  node_capacity_type  = include.env.locals.node_capacity_type
  node_instance_types = include.env.locals.node_instance_types
  node_desired_size   = include.env.locals.node_desired_size
  node_min_size       = include.env.locals.node_min_size
  node_max_size       = include.env.locals.node_max_size
  node_disk_size      = include.env.locals.node_disk_size
  
  # Tags
  tags = include.env.locals.common_tags
}
