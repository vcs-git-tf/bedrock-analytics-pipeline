# Remove the invalid service-linked role:
# resource "aws_iam_service_linked_role" "athena" { ... }

# Create IAM role for Athena operations (if needed for cross-service access)
resource "aws_iam_role" "athena_execution_role" {
  name = "${var.project_name}-${var.environment}-athena-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for Athena to access S3 and Glue
resource "aws_iam_policy" "athena_execution_policy" {
  name        = "${var.project_name}-${var.environment}-athena-execution-policy"
  description = "Policy for Athena to access S3 and Glue resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.athena_results.arn,
          "${aws_s3_bucket.athena_results.arn}/*"
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

# Attach policy to role
resource "aws_iam_role_policy_attachment" "athena_execution_policy_attachment" {
  role       = aws_iam_role.athena_execution_role.name
  policy_arn = aws_iam_policy.athena_execution_policy.arn
}

# S3 bucket for Athena query results
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-${var.environment}-metrics"

  tags = merge(var.tags, {
    Component = "athena"
    Purpose   = "query-results"
  })
}

# Bucket policy to allow Athena service access
resource "aws_s3_bucket_policy" "athena_results_policy" {
  bucket = aws_s3_bucket.athena_results.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCurrentAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.athena_results.arn,
          "${aws_s3_bucket.athena_results.arn}/*"
        ]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.athena_results]
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Ensure bucket is private
resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Athena workgroup with proper configuration
resource "aws_athena_workgroup" "bedrock_analytics" {
  name = "${var.project_name}-${var.environment}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
  }

  # Update dependencies to use the IAM role instead of service-linked role
  depends_on = [
    aws_s3_bucket.athena_results,
    aws_s3_bucket_policy.athena_results_policy,
    aws_iam_role.athena_execution_role
  ]

  tags = merge(var.tags, {
    Component = "athena"
  })
}

# Athena database
resource "aws_athena_database" "bedrock_analytics" {
  name   = var.database_name
  bucket = aws_s3_bucket.athena_results.bucket

  depends_on = [aws_athena_workgroup.bedrock_analytics]
}