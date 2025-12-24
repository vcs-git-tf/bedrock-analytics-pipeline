variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "athena_workgroup_name" {
  description = "Name of the Athena workgroup to use"
  type        = string
}

variable "athena_workgroup_arn" {
  description = "ARN of the Athena workgroup"
  type        = string
}

variable "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena results"
  type        = string
}

variable "quicksight_service_role_arn" {
  description = "ARN of the QuickSight service role"
  type        = string
}

variable "athena_database_name" {
  description = "Name of the Athena database"
  type        = string
}

variable "athena_table_name" {
  description = "Name of the Athena table"
  type        = string
  default     = "bedrock_metrics"
}

variable "quicksight_user" {
  description = "QuickSight user for permissions (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}