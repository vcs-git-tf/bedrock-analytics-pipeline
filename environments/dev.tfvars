aws_region        = "us-east-1"
project_name      = "bedrock-analytics"
environment       = "dev"
aws_account_id    = "194191748922"
quicksight_user   = "Admin"
deploy_quicksight = true
# In your terraform.tfvars or variables
athena_results_bucket_arn = "arn:aws:s3:::aws-athena-query-results-${var.aws_account_id}-${var.aws_region}"

tags = {
  Project     = "bedrock-analytics"
  Environment = "dev"
  ManagedBy   = "terraform"
  Owner       = "data-team"
}
