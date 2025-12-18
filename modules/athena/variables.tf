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
 
variable "s3_bucket_id" {
  description = "ID of the S3 bucket for metrics data"
  type        = string
}
 
variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for metrics data"
  type        = string
}
 
variable "database_name" {
  description = "Name of the Athena database"
  type        = string
}
 
variable "metrics_prefix" {
  description = "S3 prefix for metrics data"
  type        = string
  default     = "bedrock-metrics/"
}