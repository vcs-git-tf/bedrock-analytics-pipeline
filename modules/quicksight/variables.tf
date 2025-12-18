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
 
variable "athena_database_name" {
  description = "Name of the Athena database"
  type        = string
}
 
variable "athena_table_name" {
  description = "Name of the Athena table"
  type        = string
}
 
variable "quicksight_user" {
  description = "QuickSight user to grant access to the dataset"
  type        = string
}
 
variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}
 
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}