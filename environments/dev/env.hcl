# Development Environment Configuration
# This file contains all environment-specific variables for the dev environment

locals {
  # Environment identification
  environment  = "dev"
  project_name = "dev-vsf-tts"
  aws_region   = "ap-southeast-1"
  
  # Common tags applied to all resources
  common_tags = {
    Environment = "dev"
    Project     = "dev-vsf-tts"
    ManagedBy   = "Terragrunt"
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
  }
  
  # VPC Configuration
  vpc_cidr           = "10.0.0.0/16"
  single_nat_gateway = true  # Cost optimization: use single NAT gateway in dev
  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Subnet Configuration
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
  isolated_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
  
  # EKS Cluster Configuration
  cluster_version = "1.30"
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  
  # EKS Node Group Configuration
  node_capacity_type   = "SPOT"  # Use SPOT instances for cost savings in dev
  node_instance_types  = ["t3.medium", "t3.large", "t3a.medium"]
  node_desired_size    = 2
  node_min_size        = 1
  node_max_size        = 3
  node_disk_size       = 20  # GB
  
  # EKS Add-ons
  enable_ebs_csi_driver = true
  enable_alb_controller = true
  
  # Kubernetes Configuration
  k8s_namespace = "default"
  
  # Cost Optimization Settings (dev-specific)
  enable_cluster_autoscaler = false  # Disable in dev to save costs
  enable_monitoring         = false  # Disable CloudWatch Container Insights in dev
}
