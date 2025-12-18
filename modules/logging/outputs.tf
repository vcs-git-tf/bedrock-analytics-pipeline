output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.bedrock_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.bedrock_logs.arn
}

output "bedrock_logging_role_arn" {
  description = "ARN of the Bedrock logging role"
  value       = aws_iam_role.bedrock_logging_role.arn
}