terraform {
  backend "s3" {
    # These values must be provided via command line or environment variables
    bucket         = "bedrock-analytics-dev-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    # dynamodb_table = "bedrock-analytics-dev-terraform-locks"
    encrypt        = true
  }
}