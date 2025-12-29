output "metrics_bucket_name" {
  description = "Name of the S3 bucket storing metrics data"
  value       = module.storage.metrics_bucket_id
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.logging.log_group_name
}

output "firehose_delivery_stream_name" {
  description = "Name of the Kinesis Firehose delivery stream"
  value       = module.firehose.delivery_stream_name
}

output "athena_database_name" {
  description = "Name of the Athena database"
  value       = module.athena.database_name
}

output "bedrock_logging_role_arn" {
  description = "ARN of the Bedrock logging role"
  value       = module.logging.bedrock_logging_role_arn
}

# output "quicksight_dataset_arn" {
#   description = "ARN of the QuickSight dataset"
#   value       = var.deploy_quicksight ? module.quicksight.quicksight_dataset_arn : null
# }