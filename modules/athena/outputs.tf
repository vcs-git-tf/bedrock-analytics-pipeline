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