aws_region        = "us-east-1"
project_name      = "bedrock-analytics"
environment       = "dev"
aws_account_id    = "194191748922"
quicksight_user   = "arn:aws:iam::194191748922:user/tfAdmin01"
deploy_quicksight = true

tags = {
  Project     = "bedrock-analytics"
  Environment = "dev"
  ManagedBy   = "terraform"
  Owner       = "data-team"
}
