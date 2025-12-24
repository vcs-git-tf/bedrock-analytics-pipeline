# Add variables to receive dependencies from athena module
variable "athena_workgroup_arn" {
  description = "ARN of the Athena workgroup"
  type        = string
}

variable "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena results"
  type        = string
}

variable "quicksight_service_role_arn" {
  description = "ARN of the QuickSight service role"
  type        = string
}

# Create QuickSight data source without inline permissions
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

  lifecycle {
    create_before_destroy = true
  }
}

# Separate resource for QuickSight data source permissions
resource "aws_quicksight_data_source_permissions" "athena_source_permissions" {
  aws_account_id = var.aws_account_id
  data_source_id = aws_quicksight_data_source.athena_source.data_source_id

  permissions {
    principal = var.quicksight_service_role_arn
    actions = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource"
    ]
  }

  # Add permissions for QuickSight user if specified
  dynamic "permissions" {
    for_each = var.quicksight_user != "" ? [1] : []
    content {
      principal = "arn:aws:quicksight:${var.aws_region}:${var.aws_account_id}:user/${var.quicksight_user}"
      actions = [
        "quicksight:DescribeDataSource",
        "quicksight:DescribeDataSourcePermissions",
        "quicksight:PassDataSource"
      ]
    }
  }

  depends_on = [aws_quicksight_data_source.athena_source]
}

# Create QuickSight dataset with proper configuration
locals {
  dataset_id = "${var.project_name}-${var.environment}-metrics-${substr(md5("${var.project_name}-${var.environment}"), 0, 8)}"
}

resource "aws_quicksight_data_set" "bedrock_metrics_dataset" {
  data_set_id    = local.dataset_id
  name           = "${var.project_name}-${var.environment}-metrics-dataset"
  aws_account_id = var.aws_account_id
  import_mode    = "SPICE"

  physical_table_map {
    physical_table_map_id = "BedrockMetricsTable"

    relational_table {
      data_source_arn = aws_quicksight_data_source.athena_source.arn
      schema          = var.athena_database_name
      name            = var.athena_table_name

      input_columns {
        name = "requestid"
        type = "STRING"
      }

      input_columns {
        name = "modelid"
        type = "STRING"
      }

      input_columns {
        name = "latencyms"
        type = "DECIMAL"
      }

      input_columns {
        name = "inputtokencount"
        type = "INTEGER"
      }

      input_columns {
        name = "outputtokencount"
        type = "INTEGER"
      }

      input_columns {
        name = "totaltokencount"
        type = "INTEGER"
      }

      input_columns {
        name = "timestamp"
        type = "DATETIME"
      }
    }
  }

  logical_table_map {
    logical_table_map_id = "BedrockMetricsLogicalTable"

    alias = "bedrock_metrics"
    source {
      physical_table_id = "BedrockMetricsTable"
    }
  }

  refresh_properties {
    refresh_configuration {
      incremental_refresh {
        lookback_window {
          column_name = "timestamp"
          size        = 5
          size_unit   = "DAY"
        }
      }
    }
  }

  depends_on = [
    aws_quicksight_data_source.athena_source,
    aws_quicksight_data_source_permissions.athena_source_permissions
  ]

  tags = var.tags
}

# Separate resource for dataset permissions
resource "aws_quicksight_data_set_permissions" "bedrock_metrics_dataset_permissions" {
  aws_account_id = var.aws_account_id
  data_set_id    = aws_quicksight_data_set.bedrock_metrics_dataset.data_set_id

  permissions {
    principal = var.quicksight_service_role_arn
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet"
    ]
  }

  # Add permissions for QuickSight user if specified
  dynamic "permissions" {
    for_each = var.quicksight_user != "" ? [1] : []
    content {
      principal = "arn:aws:quicksight:${var.aws_region}:${var.aws_account_id}:user/${var.quicksight_user}"
      actions = [
        "quicksight:DescribeDataSet",
        "quicksight:DescribeDataSetPermissions",
        "quicksight:PassDataSet",
        "quicksight:UpdateDataSet",
        "quicksight:DeleteDataSet"
      ]
    }
  }

  depends_on = [aws_quicksight_data_set.bedrock_metrics_dataset]
}