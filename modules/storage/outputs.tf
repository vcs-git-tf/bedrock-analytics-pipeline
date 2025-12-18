output "metrics_bucket_id" {
  description = "ID of the S3 bucket for metrics data"
  value       = aws_s3_bucket.metrics_bucket.id
}
 
output "metrics_bucket_arn" {
  description = "ARN of the S3 bucket for metrics data"
  value       = aws_s3_bucket.metrics_bucket.arn
}