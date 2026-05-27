# Variables for App Layer

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "dev-vsf-tts"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# EKS Cluster Information (passed from Terragrunt dependency)
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  type        = string
}

# Kubernetes Configuration
variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "default"
}

variable "create_namespace" {
  description = "Whether to create the namespace (set to false if using default)"
  type        = bool
  default     = false
}

# Nginx Configuration
variable "nginx_image" {
  description = "Nginx container image"
  type        = string
  default     = "nginx:alpine"
}

variable "nginx_replicas" {
  description = "Number of nginx replicas"
  type        = number
  default     = 2
}

variable "nginx_cpu_request" {
  description = "CPU request for nginx container"
  type        = string
  default     = "100m"
}

variable "nginx_memory_request" {
  description = "Memory request for nginx container"
  type        = string
  default     = "128Mi"
}

variable "nginx_cpu_limit" {
  description = "CPU limit for nginx container"
  type        = string
  default     = "200m"
}

variable "nginx_memory_limit" {
  description = "Memory limit for nginx container"
  type        = string
  default     = "256Mi"
}

# ALB Configuration
variable "alb_scheme" {
  description = "ALB scheme (internet-facing or internal)"
  type        = string
  default     = "internet-facing"
}
