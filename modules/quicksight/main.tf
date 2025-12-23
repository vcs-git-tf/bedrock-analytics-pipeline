# Remove the S3 bucket resources entirely from QuickSight module

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

  tags = var.tags
}