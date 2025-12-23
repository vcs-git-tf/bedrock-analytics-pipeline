# modules/athena/main.tf

# Create S3 bucket with proper configuration for Athena
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.project_name}-${var.environment}-metrics"
  force_destroy = true # Allow Terraform to delete bucket even if not empty

  tags = merge(var.tags, {
    Component = "athena"
    Purpose   = "query-results"
  })
}

# Ensure bucket is private
resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add versioning
resource "aws_s3_bucket_versioning" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Create a test object to ensure bucket is working
resource "aws_s3_object" "test_object" {
  bucket  = aws_s3_bucket.athena_results.id
  key     = "query-results/.keep"
  content = "This file ensures the query-results prefix exists"

  depends_on = [aws_s3_bucket.athena_results]
}

# Athena workgroup with explicit bucket reference
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

  # Ensure bucket is ready before creating workgroup
  depends_on = [
    aws_s3_bucket.athena_results,
    aws_s3_bucket_server_side_encryption_configuration.athena_results,
    aws_s3_object.test_object
  ]

  tags = merge(var.tags, {
    Component = "athena"
  })
}

# Athena database
resource "aws_athena_database" "bedrock_analytics" {
  name   = var.database_name
  bucket = aws_s3_bucket.athena_results.bucket

  depends_on = [
    aws_athena_workgroup.bedrock_analytics
  ]
}