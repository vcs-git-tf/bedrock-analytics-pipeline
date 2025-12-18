resource "aws_cloudwatch_log_group" "bedrock_logs" {
  name              = "bedrock-logs"
  retention_in_days = var.log_retention
  tags              = var.tags
}

resource "aws_iam_role" "bedrock_logging_role" {
  name = var.bedrock_logging_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "bedrock_logging_policy" {
  name        = "${var.bedrock_logging_role_name}-policy"
  description = "Policy for Bedrock logging to CloudWatch and S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.bedrock_logs.arn}",
          "${aws_cloudwatch_log_group.bedrock_logs.arn}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_logging_attachment" {
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