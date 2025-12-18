# backend/variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Create local tags that combine defaults with provided tags
locals {
  default_tags = {
    Project   = var.project_name
    Environment = var.environment
    ManagedBy = "terraform"
  }
  
  tags = merge(local.default_tags, var.tags)
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
