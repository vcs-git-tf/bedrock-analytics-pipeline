resource "aws_iam_role" "firehose_role" {
  name = "${var.project_name}-${var.environment}-firehose-role"
 
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
 
  tags = var.tags
}
 
resource "aws_iam_policy" "firehose_s3_policy" {
  name        = "${var.project_name}-${var.environment}-firehose-s3-policy"
  description = "Policy for Firehose to write to S3"
 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}
 
resource "aws_iam_role_policy_attachment" "firehose_s3_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_s3_policy.arn
}
 
resource "aws_kinesis_firehose_delivery_stream" "bedrock_metrics_stream" {
  name        = "${var.project_name}-${var.environment}-metrics-stream"
  destination = "extended_s3"
 
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = var.s3_bucket_arn
    prefix     = var.metrics_prefix
   
    buffering_interval = var.firehose_buffer_interval
    buffering_size     = var.firehose_buffer_size
   
    compression_format = "GZIP"
   
    error_output_prefix = "${var.metrics_prefix}error/"
   
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "${var.project_name}-${var.environment}-firehose-logs"
      log_stream_name = "S3Delivery"
    }
  }
 
  tags = var.tags
}
 
resource "aws_cloudwatch_log_group" "firehose_logs" {
  name              = "${var.project_name}-${var.environment}-firehose-logs"
  retention_in_days = 7
  tags              = var.tags
}
 
resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose_logs.name
}
 
resource "aws_iam_role" "cloudwatch_subscription_role" {
  name = "${var.project_name}-${var.environment}-cw-subscription-role"
 
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
 
  tags = var.tags
}
 
resource "aws_iam_policy" "cloudwatch_firehose_policy" {
  name        = "${var.project_name}-${var.environment}-cw-firehose-policy"
  description = "Policy for CloudWatch to write to Firehose"
 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [
          aws_kinesis_firehose_delivery_stream.bedrock_metrics_stream.arn
        ]
      }
    ]
  })
}
 
resource "aws_iam_role_policy_attachment" "cloudwatch_firehose_attachment" {
  role       = aws_iam_role.cloudwatch_subscription_role.name
  policy_arn = aws_iam_policy.cloudwatch_firehose_policy.arn
}
 
resource "aws_cloudwatch_log_subscription_filter" "bedrock_to_firehose" {
  name            = "${var.project_name}-${var.environment}-bedrock-to-firehose"
  log_group_name  = var.log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.bedrock_metrics_stream.arn
  role_arn        = aws_iam_role.cloudwatch_subscription_role.arn
}