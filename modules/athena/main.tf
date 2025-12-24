# Get current AWS account and caller identity
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# S3 bucket for Athena query results
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-${var.environment}-metrics"
  
  tags = merge(var.tags, {
    Component = "athena"
    Purpose   = "query-results"
  })
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
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
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Comprehensive IAM policy for QuickSight-Athena integration
resource "aws_iam_policy" "quicksight_athena_policy" {
  name        = "${var.project_name}-${var.environment}-quicksight-athena-policy"
  description = "Comprehensive policy for QuickSight to access Athena, S3, and Glue"

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
          "athena:StopQueryExecution",
          "athena:GetDataCatalog",
          "athena:GetDatabase",
          "athena:GetTableMetadata",
          "athena:ListDatabases",
          "athena:ListDataCatalogs",
          "athena:ListTableMetadata",
          "athena:ListWorkGroups"
        ]
        Resource = "*"
      },
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
          "s3:PutObjectAcl",
          "s3:CreateBucket"
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
          "glue:GetPartitions",
          "glue:GetCatalogImportStatus",
          "glue:CreateDatabase",
          "glue:CreateTable"
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

# S3 bucket policy allowing QuickSight and Athena access
resource "aws_s3_bucket_policy" "athena_results_policy" {
  bucket = aws_s3_bucket.athena_results.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowQuickSightAndAthenaAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.quicksight_athena_role.arn,
            "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
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

  depends_on = [
    aws_s3_bucket_public_access_block.athena_results,
    aws_iam_role.quicksight_athena_role
  ]
}

# Athena workgroup with enhanced configuration
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

  depends_on = [
    aws_s3_bucket.athena_results,
    aws_s3_bucket_policy.athena_results_policy,
    aws_iam_role.quicksight_athena_role
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