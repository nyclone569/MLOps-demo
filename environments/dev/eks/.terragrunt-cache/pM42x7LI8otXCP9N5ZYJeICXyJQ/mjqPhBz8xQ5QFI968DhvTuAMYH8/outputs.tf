output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN — dùng cho IRSA"
  value       = module.eks.oidc_provider_arn
}

output "alb_controller_role_arn" {
  description = "IAM Role ARN cho ALB Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "alb_controller_helm_release_status" {
  description = "Status of AWS Load Balancer Controller Helm release"
  value       = helm_release.aws_load_balancer_controller.status
}