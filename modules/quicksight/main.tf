# In modules/quicksight/main.tf - Enhanced locals
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

# Complete corrected aws_quicksight_data_set resource
resource "aws_quicksight_data_set" "bedrock_metrics_dataset" {
  data_set_id    = "${var.project_name}-${var.environment}-dataset_id"
  name           = "${var.project_name}-${var.environment}-metrics-dataset"
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

  # Service role permissions (always present)
  permissions {
    principal = aws_iam_role.quicksight_service_role.arn
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:CreateIngestion",
      "quicksight:CancelIngestion",
      "quicksight:ListIngestions",
      "quicksight:DescribeIngestion"
    ]
  }

  # User permissions (conditional) - CORRECTED
  dynamic "permissions" {
    for_each = var.quicksight_user != null ? [var.quicksight_user] : []
    content {
      principal = permissions.value
      actions = [
        "quicksight:DescribeDataSet",
        "quicksight:DescribeDataSetPermissions",
        "quicksight:PassDataSet",
        "quicksight:UpdateDataSet",
        "quicksight:DeleteDataSet"
      ]
    }
  }

  # Refresh properties for SPICE datasets - CORRECTED
  dynamic "refresh_properties" {
    for_each = var.dataset_import_mode == "SPICE" ? [1] : []
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

  tags = var.tags
}

# Complete corrected aws_quicksight_analysis resource
resource "aws_quicksight_analysis" "bedrock_metrics_analysis" {
  count = var.create_analysis ? 1 : 0

  analysis_id    = "${var.project_name}-${var.environment}-analysis"
  name           = "${var.project_name}-${var.environment} Bedrock Metrics Analysis"
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

      # Simple table visual
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

  # Service role permissions (always present)
  permissions {
    principal = aws_iam_role.quicksight_service_role.arn
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

  # User permissions (conditional) - CORRECTED
  dynamic "permissions" {
    for_each = var.quicksight_user != null ? [var.quicksight_user] : []
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

  tags = var.tags
}

# Complete corrected aws_quicksight_dashboard resource
resource "aws_quicksight_dashboard" "bedrock_metrics_dashboard" {
  count = var.create_analysis && var.create_dashboard ? 1 : 0

  dashboard_id        = "${var.project_name}-${var.environment}-dashboard"
  name                = "${var.project_name}-${var.environment} Bedrock Metrics Dashboard"
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

  # Service role permissions (always present)
  permissions {
    principal = aws_iam_role.quicksight_service_role.arn
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

  # User permissions (conditional) - CORRECTED
  dynamic "permissions" {
    for_each = var.quicksight_user != null ? [var.quicksight_user] : []
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

  tags = var.tags
}