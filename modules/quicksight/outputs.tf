# Analysis outputs
output "quicksight_analysis_arn" {
  description = "ARN of the QuickSight analysis"
  value       = var.create_analysis ? aws_quicksight_analysis.bedrock_metrics_analysis[0].arn : null
}

output "quicksight_analysis_id" {
  description = "ID of the QuickSight analysis"
  value       = var.create_analysis ? aws_quicksight_analysis.bedrock_metrics_analysis[0].analysis_id : null
}

# Dashboard outputs (FIXED syntax)
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