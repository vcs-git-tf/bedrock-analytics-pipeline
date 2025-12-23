output "quicksight_data_source_arn" {
  description = "ARN of the QuickSight data source"
  value       = aws_quicksight_data_source.athena_source.arn
}

output "quicksight_data_source_id" {
  description = "ID of the QuickSight data source"
  value       = aws_quicksight_data_source.athena_source.data_source_id
}

output "quicksight_dataset_arn" {
  description = "ARN of the QuickSight dataset"
  value       = module.quicksight.quicksight_dataset_arn
}