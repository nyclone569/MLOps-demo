# Outputs for App Layer

output "namespace" {
  description = "Kubernetes namespace where the app is deployed"
  value       = var.namespace
}

output "deployment_name" {
  description = "Name of the nginx deployment"
  value       = kubernetes_deployment.nginx.metadata[0].name
}

output "service_name" {
  description = "Name of the nginx service"
  value       = kubernetes_service.nginx.metadata[0].name
}

output "ingress_name" {
  description = "Name of the nginx ingress"
  value       = kubernetes_ingress_v1.nginx.metadata[0].name
}

output "alb_hostname" {
  description = "ALB hostname (may take 2-3 minutes to be available after first apply)"
  value       = try(kubernetes_ingress_v1.nginx.status[0].load_balancer[0].ingress[0].hostname, "⏳ Pending - ALB is being provisioned...")
}

output "application_url" {
  description = "Application URL (access your nginx application here)"
  value       = try("http://${kubernetes_ingress_v1.nginx.status[0].load_balancer[0].ingress[0].hostname}", "⏳ Pending - run 'terragrunt refresh' or 'terragrunt output' after 2-3 minutes")
}

output "get_url_command" {
  description = "Command to get the ALB URL using kubectl"
  value       = "kubectl get ingress ${kubernetes_ingress_v1.nginx.metadata[0].name} -n ${var.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "kubectl_commands" {
  description = "Useful kubectl commands"
  value = <<-EOT
    
    ╔════════════════════════════════════════════════════════════════╗
    ║  Application Deployed Successfully!                            ║
    ╚════════════════════════════════════════════════════════════════╝
    
    Namespace: ${var.namespace}
    
    🌐 GET APPLICATION URL:
    
    Method 1: Using Terraform output (wait 2-3 minutes after first apply)
      terragrunt output application_url
      # or
      terragrunt refresh && terragrunt output application_url
    
    Method 2: Using kubectl
      kubectl get ingress ${kubernetes_ingress_v1.nginx.metadata[0].name} -n ${var.namespace}
      
      # Get URL directly
      export ALB_URL=$(kubectl get ingress ${kubernetes_ingress_v1.nginx.metadata[0].name} -n ${var.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
      echo "Application URL: http://$ALB_URL"
    
    Method 3: Using AWS CLI
      aws elbv2 describe-load-balancers --region ${var.region} --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-${var.namespace}`)].DNSName' --output text
    
    📊 CHECK STATUS:
      kubectl get deployments -n ${var.namespace}
      kubectl get pods -n ${var.namespace}
      kubectl get services -n ${var.namespace}
      kubectl get ingress -n ${var.namespace}
    
    📝 VIEW LOGS:
      kubectl logs -l app=nginx -n ${var.namespace}
      kubectl logs -l app=nginx -n ${var.namespace} --tail=50 -f
    
    🔧 SCALE DEPLOYMENT:
      kubectl scale deployment nginx --replicas=3 -n ${var.namespace}
    
    🧪 TEST APPLICATION:
      # Wait for ALB to be ready, then:
      curl http://$(kubectl get ingress ${kubernetes_ingress_v1.nginx.metadata[0].name} -n ${var.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    ⚠️  NOTE: ALB takes 2-3 minutes to provision after first apply.
        If URL shows "Pending", wait a bit and run: terragrunt refresh
    
  EOT
}
