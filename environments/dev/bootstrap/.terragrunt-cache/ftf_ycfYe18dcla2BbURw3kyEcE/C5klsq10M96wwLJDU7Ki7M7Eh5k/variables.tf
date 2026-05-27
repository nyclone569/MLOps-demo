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
