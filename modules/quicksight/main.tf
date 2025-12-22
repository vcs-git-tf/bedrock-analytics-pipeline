# Create or reference the Athena workgroup with proper configuration
resource "aws_athena_workgroup" "bedrock_analytics" {
  name = "${var.project_name}-${var.environment}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = merge(var.tags, {
    Component = "athena"
  })
}

# Update your QuickSight data source to depend on the workgroup
resource "aws_quicksight_data_source" "athena_source" {
  data_source_id = "${var.project_name}-${var.environment}-athena-source"
  name           = "${var.project_name}-${var.environment}-athena-source"
  type           = "ATHENA"
  aws_account_id = var.aws_account_id

  parameters {
    athena {
      work_group = aws_athena_workgroup.bedrock_analytics.name
    }
  }

  depends_on = [
    aws_athena_workgroup.bedrock_analytics,
    aws_s3_bucket.athena_results
  ]

  tags = var.tags
}

resource "aws_quicksight_data_source" "athena_source" {
  data_source_id = "${var.project_name}-${var.environment}-athena-source"
  name           = "${var.project_name}-${var.environment}-athena-source"
  type           = "ATHENA"
  aws_account_id = var.aws_account_id

  parameters {
    athena {
      work_group = "${var.project_name}-${var.environment}-workgroup"
    }
  }
}


locals {
  # Generate a consistent hash-based ID
  dataset_id = "${var.project_name}-${var.environment}-metrics-${substr(md5("${var.project_name}-${var.environment}"), 0, 8)}"
}

resource "aws_quicksight_data_set" "bedrock_metrics_dataset" {
  data_set_id    = local.dataset_id
  name           = "${var.project_name}-${var.environment}-metrics-dataset"
  aws_account_id = var.aws_account_id
  import_mode    = "SPICE" # Changed from DIRECT_QUERY

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

  permissions {
    principal = "arn:aws:quicksight:${var.aws_region}:${var.aws_account_id}:user/${var.quicksight_user}"
    actions   = ["quicksight:DescribeDataSet", "quicksight:DescribeDataSetPermissions", "quicksight:PassDataSet", "quicksight:UpdateDataSet", "quicksight:DeleteDataSet"]
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
}

# This is a placeholder as Terraform doesn't directly support QuickSight dashboard creation
# You would typically create dashboards through the QuickSight UI or API
resource "aws_cloudformation_stack" "quicksight_dashboard" {
  name = "${var.project_name}-${var.environment}-qs-dashboard"

  template_body = <<EOF
{
  "Resources": {
    "QuickSightDashboard": {
      "Type": "AWS::QuickSight::Dashboard",
      "Properties": {
        "AwsAccountId": "${var.aws_account_id}",
        "DashboardId": "${var.project_name}-${var.environment}-dashboard",
        "Name": "${var.project_name} ${var.environment} Dashboard",
        "Permissions": [
          {
            "Principal": "arn:aws:quicksight:${var.aws_region}:${var.aws_account_id}:user/${var.quicksight_user}",
            "Actions": [
              "quicksight:DescribeDashboard",
              "quicksight:ListDashboardVersions",
              "quicksight:UpdateDashboardPermissions",
              "quicksight:QueryDashboard",
              "quicksight:UpdateDashboard",
              "quicksight:DeleteDashboard",
              "quicksight:DescribeDashboardPermissions",
              "quicksight:UpdateDashboardPublishedVersion"
            ]
          }
        ],
        "SourceEntity": {
          "SourceTemplate": {
            "DataSetReferences": [
              {
                "DataSetPlaceholder": "bedrock_metrics_dataset",
                "DataSetArn": "${aws_quicksight_data_set.bedrock_metrics_dataset.arn}"
              }
            ]
          }
        }
      }
    }
  }
}
EOF
}