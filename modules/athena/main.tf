# modules/athena/main.tf - CORRECTED VERSION

# Get current AWS account and caller identity
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# Reference the S3 bucket created in the storage module
data "aws_s3_bucket" "athena_results" {
  bucket = var.athena_results_bucket_name
}

# REMOVE ALL S3 BUCKET RESOURCES - They belong in the storage module
# Don't create: aws_s3_bucket, aws_s3_bucket_versioning, 
# aws_s3_bucket_server_side_encryption_configuration, 
# aws_s3_bucket_public_access_block, aws_s3_bucket_policy

# Create Athena workgroup that uses the existing bucket
resource "aws_athena_workgroup" "bedrock_analytics" {
  name = "${var.project_name}-${var.environment}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.athena_results_bucket_name}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = var.tags
}

# Athena database
resource "aws_athena_database" "bedrock_analytics" {
  name   = var.database_name
  bucket = var.athena_results_bucket_name

  depends_on = [aws_athena_workgroup.bedrock_analytics]
}

# IAM role for QuickSight to access Athena and S3
resource "aws_iam_role" "quicksight_athena_role" {
  name = "${var.project_name}-${var.environment}-quicksight-athena-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM policy for QuickSight-Athena integration
resource "aws_iam_policy" "quicksight_athena_policy" {
  name        = "${var.project_name}-${var.environment}-quicksight-athena-policy"
  description = "Policy for QuickSight to access Athena and S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:BatchGetQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "athena:ListQueryExecutions",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          var.athena_results_bucket_arn,       # Use variable instead of resource
          "${var.athena_results_bucket_arn}/*" # Use variable instead of resource
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach policy to QuickSight role
resource "aws_iam_role_policy_attachment" "quicksight_athena_policy_attachment" {
  role       = aws_iam_role.quicksight_athena_role.name
  policy_arn = aws_iam_policy.quicksight_athena_policy.arn
}