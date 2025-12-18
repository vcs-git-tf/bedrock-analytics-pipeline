resource "aws_s3_bucket" "metrics_bucket" {
  bucket        = "${var.project_name}-${var.environment}-metrics"
  force_destroy = var.s3_force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "metrics_bucket" {
  bucket = aws_s3_bucket.metrics_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "metrics_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.metrics_bucket]

  bucket = aws_s3_bucket.metrics_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "metrics_bucket" {
  bucket = aws_s3_bucket.metrics_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "metrics_bucket" {
  bucket = aws_s3_bucket.metrics_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "metrics_bucket" {
  bucket = aws_s3_bucket.metrics_bucket.id

  rule {
    id     = "delete_old_objects"
    status = "Enabled"

    # Use filter instead of prefix
    filter {
      prefix = "logs/" # Apply to objects with this prefix
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}