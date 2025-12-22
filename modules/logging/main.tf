locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "logging"
  })
}

resource "aws_cloudwatch_log_group" "bedrock_logs" {
  name              = "bedrock-analytics-logs"
  retention_in_days = var.log_retention
  tags              = var.tags
}

resource "aws_iam_role" "bedrock_logging_role" {
  name = "${local.name_prefix}-logging-role" # bedrock-analytics-dev-logging-role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "bedrock.amazonaws.com",
            "logs.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "bedrock_logging_policy" {
  name        = "${local.name_prefix}-logging-policy" # bedrock-analytics-dev-logging-policy
  description = "Policy for Bedrock logging operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "bedrock_logging_policy_attachment" {
  role       = aws_iam_role.bedrock_logging_role.name
  policy_arn = aws_iam_policy.bedrock_logging_policy.arn
}

resource "aws_cloudwatch_log_metric_filter" "bedrock_latency" {
  name           = "BedrockLatency"
  pattern        = "{ $.latencyMs = * }"
  log_group_name = aws_cloudwatch_log_group.bedrock_logs.name

  metric_transformation {
    name      = "BedrockLatency"
    namespace = "BedrockMetrics"
    value     = "$.latencyMs"
  }
}

resource "aws_cloudwatch_log_metric_filter" "bedrock_token_count" {
  name           = "BedrockTokenCount"
  pattern        = "{ $.totalTokenCount = * }"
  log_group_name = aws_cloudwatch_log_group.bedrock_logs.name

  metric_transformation {
    name      = "BedrockTokenCount"
    namespace = "BedrockMetrics"
    value     = "$.totalTokenCount"
  }
}

resource "aws_cloudwatch_log_metric_filter" "bedrock_input_token_count" {
  name           = "BedrockInputTokenCount"
  pattern        = "{ $.inputTokenCount = * }"
  log_group_name = aws_cloudwatch_log_group.bedrock_logs.name

  metric_transformation {
    name      = "BedrockInputTokenCount"
    namespace = "BedrockMetrics"
    value     = "$.inputTokenCount"
  }
}

resource "aws_cloudwatch_log_metric_filter" "bedrock_output_token_count" {
  name           = "BedrockOutputTokenCount"
  pattern        = "{ $.outputTokenCount = * }"
  log_group_name = aws_cloudwatch_log_group.bedrock_logs.name

  metric_transformation {
    name      = "BedrockOutputTokenCount"
    namespace = "BedrockMetrics"
    value     = "$.outputTokenCount"
  }
}