resource "aws_athena_database" "bedrock_analytics" {
  name   = var.database_name
  bucket = var.s3_bucket_id
}

# Remove this resource block entirely:
# resource "aws_athena_workgroup" "bedrock_analytics" { ... }

# Replace with a data source if the athena module needs to reference it:
data "aws_athena_workgroup" "bedrock_analytics" {
  name = "${var.project_name}-${var.environment}-workgroup"
}

# Using aws_athena_named_query as a workaround since Terraform doesn't have a direct resource for creating tables
resource "aws_athena_named_query" "create_table" {
  name      = "${var.project_name}-${var.environment}-create-table"
  workgroup = aws_athena_workgroup.bedrock_analytics.name
  database  = aws_athena_database.bedrock_analytics.name
  query     = <<EOF
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