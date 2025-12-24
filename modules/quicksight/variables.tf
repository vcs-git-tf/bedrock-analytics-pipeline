# Required variables
variable "project_name" {
  description = "Name of the project"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be a 12-digit number."
  }
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  type        = string
}

variable "athena_workgroup_arn" {
  description = "ARN of the Athena workgroup"
  type        = string
}

variable "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena results"
  type        = string
}

variable "athena_database_name" {
  description = "Name of the Athena database"
  type        = string
}

variable "athena_table_name" {
  description = "Name of the Athena table"
  type        = string
  default     = "bedrock_metrics"
}

# Optional variables with defaults
variable "quicksight_user" {
  description = "QuickSight user name for permissions (optional)"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-zA-Z0-9@._-]*$", var.quicksight_user))
    error_message = "QuickSight user must contain only alphanumeric characters, @, ., _, or - symbols."
  }
}

variable "dataset_import_mode" {
  description = "Import mode for QuickSight dataset (SPICE or DIRECT_QUERY)"
  type        = string
  default     = "SPICE"

  validation {
    condition     = contains(["SPICE", "DIRECT_QUERY"], var.dataset_import_mode)
    error_message = "Dataset import mode must be either SPICE or DIRECT_QUERY."
  }
}

variable "create_analysis" {
  description = "Whether to create a QuickSight analysis"
  type        = bool
  default     = true
}

variable "create_dashboard" {
  description = "Whether to create a QuickSight dashboard"
  type        = bool
  default     = true
}

variable "enable_refresh_schedule" {
  description = "Whether to enable refresh schedule for SPICE datasets"
  type        = bool
  default     = false
}

variable "refresh_lookback_window_size" {
  description = "Size of the lookback window for incremental refresh"
  type        = number
  default     = 5

  validation {
    condition     = var.refresh_lookback_window_size > 0 && var.refresh_lookback_window_size <= 365
    error_message = "Refresh lookback window size must be between 1 and 365."
  }
}

variable "refresh_lookback_window_unit" {
  description = "Unit for the lookback window (DAY, HOUR, WEEK, MONTH)"
  type        = string
  default     = "DAY"

  validation {
    condition     = contains(["DAY", "HOUR", "WEEK", "MONTH"], var.refresh_lookback_window_unit)
    error_message = "Refresh lookback window unit must be one of: DAY, HOUR, WEEK, MONTH."
  }
}

variable "refresh_start_time" {
  description = "Start time for refresh schedule (ISO 8601 format)"
  type        = string
  default     = "2024-01-01T00:00:00Z"

  validation {
    condition     = can(formatdate("RFC3339", var.refresh_start_time))
    error_message = "Refresh start time must be in valid ISO 8601 format."
  }
}

variable "refresh_timezone" {
  description = "Timezone for refresh schedule"
  type        = string
  default     = "UTC"
}

variable "refresh_interval" {
  description = "Refresh interval (DAILY, WEEKLY, MONTHLY)"
  type        = string
  default     = "DAILY"

  validation {
    condition     = contains(["DAILY", "WEEKLY", "MONTHLY"], var.refresh_interval)
    error_message = "Refresh interval must be one of: DAILY, WEEKLY, MONTHLY."
  }
}

variable "refresh_time_of_day" {
  description = "Time of day for refresh (HH:MM format)"
  type        = string
  default     = "06:00"

  validation {
    condition     = can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", var.refresh_time_of_day))
    error_message = "Refresh time of day must be in HH:MM format (24-hour)."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}