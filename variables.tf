variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "bedrock-analytics"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "bedrock-analytics"
    ManagedBy = "terraform"
  }
}

variable "s3_force_destroy" {
  description = "Whether to force destroy S3 buckets even if they contain objects"
  type        = bool
  default     = false
}

variable "log_retention" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "bedrock_logging_role_name" {
  description = "Name of the IAM role for Bedrock logging"
  type        = string
  default     = "BedrockLoggingRole"
}

variable "firehose_buffer_interval" {
  description = "Buffer interval in seconds for Firehose delivery stream"
  type        = number
  default     = 60
}

variable "firehose_buffer_size" {
  description = "Buffer size in MBs for Firehose delivery stream"
  type        = number
  default     = 5
}

variable "metrics_prefix" {
  description = "S3 prefix for metrics data"
  type        = string
  default     = "bedrock-metrics/"
}

variable "athena_database_name" {
  description = "Name of the Athena database"
  type        = string
  default     = "bedrock_analytics"
}

variable "quicksight_user" {
  description = "QuickSight user to grant access to the dataset"
  type        = string
  default     = ""
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "deploy_quicksight" {
  description = "Whether to deploy QuickSight resources"
  type        = bool
  default     = true
}