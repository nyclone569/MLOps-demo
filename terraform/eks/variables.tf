variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "dev-vsf-tts"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "dev-vsf-tts"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "t3a.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "SPOT"
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 20
}

variable "s3_backend_bucket" {
  description = "S3 bucket name for remote state"
  type        = string
  default     = "dev-vsf-tts"
}

variable "dynamodb_lock_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "dev-vsf-tts-lock"
}