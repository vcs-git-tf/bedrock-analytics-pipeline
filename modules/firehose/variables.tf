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
 
variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for metrics data"
  type        = string
}
 
variable "s3_bucket_id" {
  description = "ID of the S3 bucket for metrics data"
  type        = string
}
 
variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}
 
variable "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  type        = string
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