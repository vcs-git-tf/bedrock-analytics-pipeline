output "database_name" {
  description = "Name of the Athena database"
  value       = aws_athena_database.bedrock_analytics.name
}

output "workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.bedrock_analytics.name
}

output "table_name" {
  description = "Name of the Athena table"
  value       = "bedrock_metrics"
}

output "athena_results_bucket_name" {
  description = "Name of the S3 bucket for Athena query results"
  value       = aws_s3_bucket.athena_results.bucket
}