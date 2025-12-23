resource "aws_athena_database" "bedrock_analytics" {
  name   = var.database_name
  bucket = var.s3_bucket_id
}

resource "aws_athena_workgroup" "bedrock_analytics" {
  name = "${var.project_name}-${var.environment}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.s3_bucket_id}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = merge(var.tags, {
    Component = "athena"
  })
}

resource "aws_athena_named_query" "create_table" {
  name      = "${var.project_name}-${var.environment}-create-table"
  workgroup = aws_athena_workgroup.bedrock_analytics.name
  database  = aws_athena_database.bedrock_analytics.name

  query = <<EOF
CREATE EXTERNAL TABLE IF NOT EXISTS ${var.database_name}.bedrock_metrics (
  requestId STRING,
  modelId STRING,
  latencyMs DOUBLE,
  inputTokenCount INT,
  outputTokenCount INT,
  totalTokenCount INT,
  timestamp TIMESTAMP
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://${var.s3_bucket_id}/${var.metrics_prefix}'
TBLPROPERTIES ('has_encrypted_data'='false')
EOF
}