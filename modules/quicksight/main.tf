# Add variables to receive dependencies from athena module
variable "athena_workgroup_arn" {
  description = "ARN of the Athena workgroup"
  type        = string
}

variable "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena results"
  type        = string
}

# Data source to verify Athena workgroup is ready
data "aws_athena_workgroup" "verify_workgroup" {
  name = var.athena_workgroup_name
}

# Create QuickSight data source with explicit dependencies
resource "aws_quicksight_data_source" "athena_source" {
  data_source_id = "${var.project_name}-${var.environment}-athena-source"
  name           = "${var.project_name}-${var.environment}-athena-source"
  type           = "ATHENA"
  aws_account_id = var.aws_account_id

  parameters {
    athena {
      work_group = var.athena_workgroup_name
    }
  }

  # Explicit dependency to ensure Athena workgroup is fully configured
  depends_on = [
    data.aws_athena_workgroup.verify_workgroup
  ]

  tags = var.tags

  # Add lifecycle rule to handle creation retries
  lifecycle {
    create_before_destroy = true
  }
}