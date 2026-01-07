# modules/storage/outputs.tf (CORRECTED)
output "athena_results_bucket_name" {
  description = "Name of the S3 bucket for Athena query results"
  value       = aws_s3_bucket.metrics_bucket.bucket
}

output "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena query results"
  value       = aws_s3_bucket.metrics_bucket.arn
}

output "athena_results_bucket_id" {
  description = "ID of the S3 bucket for Athena query results"
  value       = aws_s3_bucket.metrics_bucket.id
}

# Additional useful outputs
output "metrics_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.metrics_bucket.bucket_domain_name
}

output "metrics_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.metrics_bucket.region
}

# modules/storage/outputs.tf - ADD THIS OUTPUT
output "metrics_bucket_id" {
  description = "ID of the metrics S3 bucket"
  value       = aws_s3_bucket.metrics_bucket.id
}

# modules/storage/outputs.tf - ADD THIS OUTPUT
output "metrics_bucket_arn" {
  description = "ARN of the metrics S3 bucket"
  value       = aws_s3_bucket.metrics_bucket.arn
}

output "metrics_bucket_name" {
  description = "Name of the metrics S3 bucket"
  value       = aws_s3_bucket.metrics_bucket
}