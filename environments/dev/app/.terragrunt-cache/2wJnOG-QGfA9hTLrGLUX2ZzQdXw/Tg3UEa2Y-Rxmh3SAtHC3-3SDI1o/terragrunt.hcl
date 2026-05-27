# App Module Configuration
# Deploys Kubernetes applications using Terraform (no manual kubectl needed!)

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Include environment configuration
include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

# Dependency: App needs EKS cluster to be ready
dependency "eks" {
  config_path = "../eks"
  
  # Mock outputs for plan/validate commands
  mock_outputs = {
    cluster_name                         = "mock-cluster"
    cluster_endpoint                     = "https://mock-endpoint.eks.amazonaws.com"
    cluster_certificate_authority_data   = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
  
  skip_outputs = false
}

# Point to the Terraform module
terraform {
  source = "../../../terraform/app"
  
  # Hook: Display application URL after deployment
  after_hook "show_app_url" {
    commands     = ["apply"]
    execute      = [
      "bash", "-c",
      <<-EOT
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "  Waiting for ALB to be ready..."
        echo "═══════════════════════════════════════════════════════"
        sleep 10
        
        ALB_URL=$(kubectl get ingress nginx -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        
        if [ -n "$ALB_URL" ]; then
          echo ""
          echo "✓ Application deployed successfully!"
          echo ""
          echo "Application URL: http://$ALB_URL"
          echo ""
          echo "Test with: curl http://$ALB_URL"
        else
          echo ""
          echo "⚠ ALB is still being provisioned (takes 2-3 minutes)"
          echo ""
          echo "Check status with:"
          echo "  kubectl get ingress nginx -n default"
        fi
      EOT
    ]
    run_on_error = false
  }
}

# Module inputs
inputs = {
  region       = include.env.locals.aws_region
  project_name = include.env.locals.project_name
  environment  = include.env.locals.environment
  
  # EKS cluster info from dependency
  cluster_name                       = dependency.eks.outputs.cluster_name
  cluster_endpoint                   = dependency.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.eks.outputs.cluster_certificate_authority_data
  
  # Kubernetes configuration
  namespace        = include.env.locals.k8s_namespace
  create_namespace = false  # Using default namespace
  
  # Nginx configuration
  nginx_image    = "nginx:alpine"
  nginx_replicas = 2
  
  # Resource limits
  nginx_cpu_request    = "100m"
  nginx_memory_request = "128Mi"
  nginx_cpu_limit      = "200m"
  nginx_memory_limit   = "256Mi"
  
  # ALB configuration
  alb_scheme = "internet-facing"
}
