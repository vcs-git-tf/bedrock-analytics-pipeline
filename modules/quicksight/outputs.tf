# Data Source outputs
output "quicksight_data_source_arn" {
  description = "ARN of the QuickSight data source"
  value       = aws_quicksight_data_source.athena_source.arn
}

output "quicksight_data_source_id" {
  description = "ID of the QuickSight data source"
  value       = aws_quicksight_data_source.athena_source.data_source_id
}

# Dataset outputs
output "quicksight_dataset_arn" {
  description = "ARN of the QuickSight dataset"
  value       = aws_quicksight_data_set.bedrock_metrics_dataset.arn
}

output "quicksight_dataset_id" {
  description = "ID of the QuickSight dataset"
  value       = aws_quicksight_data_set.bedrock_metrics_dataset.data_set_id
}

# IAM Role outputs
output "quicksight_service_role_arn" {
  description = "ARN of the QuickSight service IAM role"
  value       = aws_iam_role.quicksight_service_role.arn
}

output "quicksight_service_role_name" {
  description = "Name of the QuickSight service IAM role"
  value       = aws_iam_role.quicksight_service_role.name
}

# Analysis outputs
output "quicksight_analysis_arn" {
  description = "ARN of the QuickSight analysis"
  value       = var.create_analysis ? aws_quicksight_analysis.bedrock_metrics_analysis[0].arn : null
}

output "quicksight_analysis_id" {
  description = "ID of the QuickSight analysis"
  value       = var.create_analysis ? aws_quicksight_analysis.bedrock_metrics_analysis[0].analysis_id : null
}

# Dashboard outputs
output "quicksight_dashboard_arn" {
  description = "ARN of the QuickSight dashboard"
  value       = var.create_analysis && var.create_dashboard ? aws_quicksight_dashboard.bedrock_metrics_dashboard[0].arn : null
}

output "quicksight_dashboard_id" {
  description = "ID of the QuickSight dashboard"
  value       = var.create_analysis && var.create_dashboard ? aws_quicksight_dashboard.bedrock_metrics_dashboard[0].dashboard_id : null
}

output "quicksight_dashboard_url" {
  description = "URL of the QuickSight dashboard"
  value       = var.create_analysis && var.create_dashboard ? "https://${var.aws_region}.quicksight.aws.amazon.com/sn/dashboards/${aws_quicksight_dashboard.bedrock_metrics_dashboard[0].dashboard_id}" : null
}

# Refresh Schedule outputs
output "quicksight_refresh_schedule_arn" {
  description = "ARN of the QuickSight refresh schedule"
  value       = var.dataset_import_mode == "SPICE" && var.enable_refresh_schedule ? aws_quicksight_refresh_schedule.bedrock_metrics_refresh[0].arn : null
}