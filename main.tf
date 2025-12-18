module "storage" {
  source = "./modules/storage"

  project_name     = var.project_name
  environment      = var.environment
  tags             = var.tags
  s3_force_destroy = var.s3_force_destroy
}

module "logging" {
  source = "./modules/logging"

  project_name              = var.project_name
  environment               = var.environment
  tags                      = var.tags
  log_retention             = var.log_retention
  bedrock_logging_role_name = var.bedrock_logging_role_name
  s3_bucket_id              = module.storage.metrics_bucket_id
  s3_bucket_arn             = module.storage.metrics_bucket_arn
}

module "firehose" {
  source = "./modules/firehose"

  project_name             = var.project_name
  environment              = var.environment
  tags                     = local.tags
  s3_bucket_arn            = module.storage.metrics_bucket_arn
  s3_bucket_id             = module.storage.metrics_bucket_id
  log_group_name           = module.logging.log_group_name
  log_group_arn            = module.logging.log_group_arn
  firehose_buffer_interval = var.firehose_buffer_interval
  firehose_buffer_size     = var.firehose_buffer_size
  metrics_prefix           = var.metrics_prefix
}

module "athena" {
  source = "./modules/athena"

  project_name   = var.project_name
  environment    = var.environment
  tags           = local.tags
  s3_bucket_id   = module.storage.metrics_bucket_id
  s3_bucket_arn  = module.storage.metrics_bucket_arn
  database_name  = var.athena_database_name
  metrics_prefix = var.metrics_prefix
}

module "quicksight" {
  source = "./modules/quicksight"

  project_name         = var.project_name
  environment          = var.environment
  tags                 = local.tags
  athena_database_name = module.athena.database_name
  athena_table_name    = module.athena.table_name
  quicksight_user      = var.quicksight_user
  aws_account_id       = var.aws_account_id
  count                = var.deploy_quicksight ? 1 : 0
}