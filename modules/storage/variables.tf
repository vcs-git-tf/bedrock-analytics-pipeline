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
 
variable "s3_force_destroy" {
  description = "Whether to force destroy S3 buckets even if they contain objects"
  type        = bool
  default     = false
}