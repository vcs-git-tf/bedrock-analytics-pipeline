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

  project_name               = var.project_name
  environment                = var.environment
  database_name              = var.athena_database_name
  s3_bucket_id               = module.storage.metrics_bucket_id
  s3_bucket_arn              = module.storage.metrics_bucket_arn
  athena_results_bucket_name = module.storage.athena_results_bucket_name # Pass bucket name
  metrics_prefix             = var.metrics_prefix
  tags                       = local.tags

  depends_on = [module.storage]
}

module "quicksight" {
  source = "./modules/quicksight"

  project_name              = var.project_name
  environment               = var.environment
  aws_account_id            = var.aws_account_id
  aws_region                = var.aws_region
  athena_workgroup_name     = module.athena.workgroup_name
  athena_workgroup_arn      = module.athena.workgroup_arn
  athena_results_bucket_arn = module.athena.athena_results_bucket_arn
  athena_database_name      = module.athena.database_name
  athena_table_name         = "bedrock_metrics"
  quicksight_user           = var.quicksight_user
  create_analysis           = var.create_quicksight_analysis
  create_dashboard          = var.create_quicksight_dashboard
  dataset_import_mode       = var.quicksight_dataset_import_mode
  enable_refresh_schedule   = var.enable_quicksight_refresh
  tags                      = local.tags

  depends_on = [
    module.athena,
    module.storage
  ]
}