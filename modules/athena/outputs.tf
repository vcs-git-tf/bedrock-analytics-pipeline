output "workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.bedrock_analytics.name
}

output "workgroup_arn" {
  description = "ARN of the Athena workgroup"
  value       = aws_athena_workgroup.bedrock_analytics.arn
}

output "database_name" {
  description = "Name of the Athena database"
  value       = aws_athena_database.bedrock_analytics.name
}

# output "athena_results_bucket_name" {
#   description = "Name of the S3 bucket for Athena query results"
#   value       = aws_s3_bucket.athena_results.bucket
# }

# output "athena_results_bucket_arn" {
#   description = "ARN of the S3 bucket for Athena query results"
#   value       = aws_s3_bucket.athena_results.arn
# }

output "quicksight_service_role_arn" {
  description = "ARN of the QuickSight service role"
  value       = aws_iam_role.quicksight_athena_role.arn
}

# Reference the bucket through variables, not resources
output "athena_results_bucket_name" {
  description = "Name of the S3 bucket for Athena query results"
  value       = var.athena_results_bucket_name # Use variable
}

output "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena query results"
  value       = var.athena_results_bucket_arn # Use variable
}