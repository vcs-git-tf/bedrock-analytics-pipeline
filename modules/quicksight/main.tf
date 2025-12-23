# Remove this invalid data source:
# data "aws_athena_workgroup" "verify_workgroup" {
#   name = var.athena_workgroup_name
# }

# Add variables to receive dependencies from athena module
variable "athena_workgroup_arn" {
  description = "ARN of the Athena workgroup"
  type        = string
}

variable "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena results"
  type        = string
}

# Create QuickSight data source with proper dependency management
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

  # Use variable references to establish implicit dependencies
  # The fact that we're using variables from the athena module
  # ensures this resource waits for the athena module to complete

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}