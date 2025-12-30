# Data sources for current AWS context
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_quicksight_user" "current" {
  user_name = "Admin"
}

# Local values for consistent naming and configuration
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  dataset_id  = "${local.name_prefix}-metrics-${substr(md5("${var.project_name}-${var.environment}"), 0, 8)}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "quicksight"
  })

  # QuickSight user ARN construction
  quicksight_user_arn = var.quicksight_user != "" ? "arn:${data.aws_partition.current.partition}:quicksight:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:user/default/${var.quicksight_user}" : null

  # Helper collections for dynamic blocks
  user_permissions_list = local.quicksight_user_arn != null ? [local.quicksight_user_arn] : []
  spice_refresh_list    = var.dataset_import_mode == "SPICE" ? ["enabled"] : []
}

# IAM role for QuickSight service operations
resource "aws_iam_role" "quicksight_service_role" {
  name = "${local.name_prefix}-quicksight-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.aws_account_id
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for QuickSight to access Athena and S3
resource "aws_iam_policy" "quicksight_service_policy" {
  name        = "${local.name_prefix}-quicksight-service-policy"
  description = "Policy for QuickSight to access Athena, S3, and Glue resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AthenaAccess"
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
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutObject"
        ]
        Resource = [
          var.athena_results_bucket_arn,
          "${var.athena_results_bucket_arn}/*",
          "arn:aws:s3:::aws-athena-query-results-*",
          "arn:aws:s3:::aws-athena-query-results-*/*"
        ]
      },
      {
        Sid    = "GlueAccess"
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "quicksight_service_policy_attachment" {
  role       = aws_iam_role.quicksight_service_role.name
  policy_arn = aws_iam_policy.quicksight_service_policy.arn
}

# Get existing QuickSight user (assumes manual setup is done)
data "aws_quicksight_user" "admin" {
  user_name      = var.quicksight_user
  aws_account_id = data.aws_caller_identity.current.account_id
  namespace      = "default"
}

resource "aws_quicksight_data_source" "athena_source" {
  data_source_id = "${var.project_name}-${var.environment}-athena-source"
  name           = "${var.project_name} ${title(var.environment)} Athena Data Source"
  type           = "ATHENA"

  parameters {
    athena {
      work_group = var.athena_workgroup_name
    }
  }

  # permission {
  #   principal = data.aws_quicksight_user.admin.arn
  #   actions = [
  #     "quicksight:DescribeDataSource",
  #     "quicksight:DescribeDataSourcePermissions",
  #     "quicksight:PassDataSource",
  #     "quicksight:UpdateDataSource",
  #     "quicksight:DeleteDataSource",
  #     "quicksight:UpdateDataSourcePermissions"
  #   ]
  # }

  tags = var.tags
}

# Add required variables
# variable "quicksight_admin_user" {
#   description = "QuickSight admin username"
#   type        = string
#   default     = "Admin"
# }

# QuickSight Dataset
resource "aws_quicksight_data_set" "bedrock_metrics_dataset" {
  data_set_id    = local.dataset_id
  name           = "${local.name_prefix}-metrics-dataset"
  aws_account_id = var.aws_account_id
  import_mode    = var.dataset_import_mode

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

    # Add calculated fields
    data_transforms {
      create_columns_operation {
        columns {
          column_name = "cost_per_token"
          column_id   = "cost_per_token"
          expression  = "ifelse(totaltokencount > 0, latencyms / totaltokencount, 0)"
        }
      }
    }

    data_transforms {
      create_columns_operation {
        columns {
          column_name = "efficiency_score"
          column_id   = "efficiency_score"
          expression  = "ifelse(latencyms > 0, totaltokencount / latencyms * 1000, 0)"
        }
      }
    }
  }

  # # Only add user permissions if QuickSight user is specified
  # dynamic "permissions" {
  #   for_each = local.user_permissions_list
  #   content {
  #     principal = permissions.value
  #     actions = [
  #       "quicksight:DescribeDataSet",
  #       "quicksight:DescribeDataSetPermissions",
  #       "quicksight:PassDataSet",
  #       "quicksight:UpdateDataSet",
  #       "quicksight:DeleteDataSet"
  #     ]
  #   }
  # }

  permissions {
    principal = "arn:aws:quicksight:${var.aws_region}:${var.aws_account_id}:user/default/${var.quicksight_user}"
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:CreateIngestion",
      "quicksight:CancelIngestion",
      "quicksight:UpdateDataSetPermissions"
    ]
  }

  # Refresh properties for SPICE datasets
  dynamic "refresh_properties" {
    for_each = local.spice_refresh_list
    content {
      refresh_configuration {
        incremental_refresh {
          lookback_window {
            column_name = "timestamp"
            size        = var.refresh_lookback_window_size
            size_unit   = var.refresh_lookback_window_unit
          }
        }
      }
    }
  }

  depends_on = [
    aws_quicksight_data_source.athena_source
  ]

  tags = local.common_tags
}

# QuickSight Analysis
resource "aws_quicksight_analysis" "bedrock_metrics_analysis" {
  count = var.create_analysis ? 1 : 0

  analysis_id    = "${local.name_prefix}-analysis"
  name           = "${local.name_prefix} Bedrock Metrics Analysis"
  aws_account_id = var.aws_account_id

  definition {
    data_set_identifiers_declarations {
      data_set_arn = aws_quicksight_data_set.bedrock_metrics_dataset.arn
      identifier   = "bedrock_metrics_ds"
    }

    # Basic sheet configuration
    sheets {
      sheet_id = "overview_sheet"
      name     = "Overview"

      visuals {
        table_visual {
          visual_id = "metrics_table"

          title {
            visibility = "VISIBLE"
            format_text {
              plain_text = "Bedrock Metrics Summary"
            }
          }

          chart_configuration {
            field_wells {
              table_aggregated_field_wells {
                group_by {
                  categorical_dimension_field {
                    field_id = "model_dimension"
                    column {
                      data_set_identifier = "bedrock_metrics_ds"
                      column_name         = "modelid"
                    }
                  }
                }

                values {
                  numerical_measure_field {
                    field_id = "total_tokens_measure"
                    column {
                      data_set_identifier = "bedrock_metrics_ds"
                      column_name         = "totaltokencount"
                    }
                    aggregation_function {
                      simple_numerical_aggregation = "SUM"
                    }
                  }
                }

                values {
                  numerical_measure_field {
                    field_id = "avg_latency_measure"
                    column {
                      data_set_identifier = "bedrock_metrics_ds"
                      column_name         = "latencyms"
                    }
                    aggregation_function {
                      simple_numerical_aggregation = "AVERAGE"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  # Only QuickSight user permissions
  dynamic "permissions" {
    for_each = local.user_permissions_list
    content {
      principal = permissions.value
      actions = [
        "quicksight:RestoreAnalysis",
        "quicksight:UpdateAnalysisPermissions",
        "quicksight:DeleteAnalysis",
        "quicksight:QueryAnalysis",
        "quicksight:DescribeAnalysisPermissions",
        "quicksight:DescribeAnalysis",
        "quicksight:UpdateAnalysis"
      ]
    }
  }

  depends_on = [
    aws_quicksight_data_set.bedrock_metrics_dataset
  ]

  tags = local.common_tags
}

# QuickSight Dashboard
resource "aws_quicksight_dashboard" "bedrock_metrics_dashboard" {
  count = var.create_analysis && var.create_dashboard ? 1 : 0

  dashboard_id        = "${local.name_prefix}-dashboard"
  name                = "${local.name_prefix} Bedrock Metrics Dashboard"
  aws_account_id      = var.aws_account_id
  version_description = "Initial version of Bedrock metrics dashboard"

  source_entity {
    source_template {
      data_set_references {
        data_set_arn         = aws_quicksight_data_set.bedrock_metrics_dataset.arn
        data_set_placeholder = "bedrock_metrics"
      }
      arn = aws_quicksight_analysis.bedrock_metrics_analysis[0].arn
    }
  }

  # Only QuickSight user permissions
  dynamic "permissions" {
    for_each = local.user_permissions_list
    content {
      principal = permissions.value
      actions = [
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
  }

  depends_on = [
    aws_quicksight_analysis.bedrock_metrics_analysis[0]
  ]

  tags = local.common_tags
}

# Data source refresh schedule (for SPICE datasets)
resource "aws_quicksight_refresh_schedule" "bedrock_metrics_refresh" {
  count = var.dataset_import_mode == "SPICE" && var.enable_refresh_schedule ? 1 : 0

  data_set_id    = aws_quicksight_data_set.bedrock_metrics_dataset.data_set_id
  aws_account_id = var.aws_account_id
  schedule_id    = "${local.name_prefix}-refresh-schedule"

  schedule {
    refresh_type          = "INCREMENTAL_REFRESH"
    start_after_date_time = var.refresh_start_time
    # timezone              = var.refresh_timezone
    schedule_frequency {
      interval        = var.refresh_interval
      time_of_the_day = var.refresh_time_of_day
    }
  }

  depends_on = [
    aws_quicksight_data_set.bedrock_metrics_dataset
  ]
}