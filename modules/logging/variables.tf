variable "project_name" {
  description = "Name of the project"
  type        = string
}
 
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}
 
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
 
variable "log_retention" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}
 
variable "bedrock_logging_role_name" {
  description = "Name of the IAM role for Bedrock logging"
  type        = string
}
 
variable "s3_bucket_id" {
  description = "ID of the S3 bucket for metrics data"
  type        = string
}
 
variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for metrics data"
  type        = string
}