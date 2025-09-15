locals {
  log_group_sets = {
    app = {
      log_groups = var.app_log_groups
      pattern    = coalesce(var.app_log_pattern, "ERROR")
      prefix     = "AppError"
      namespace  = "AppMonitoring-${var.env}"
    }
    mariadb = {
      log_groups = var.mariadb_log_groups
      pattern    = coalesce(var.mariadb_log_pattern, "CONNECTIONERROR")
      prefix     = "MariaDBConnError"
      namespace  = "MariaDB-${var.env}"
    }
  }
}

module "cloudwatch_alarms" {
  for_each     = local.log_group_sets
  source       = "./modules/cloudwatch_alarm"

  env          = var.env
  log_groups    = each.value.log_groups
  pattern       = each.value.pattern
  namespace     = each.value.namespace
  prefix        = each.value.prefix
  sns_topic_arn = module.sns.sns_topic_arn
}

module "sns" {
  source = "./modules/sns"

  lambda_function_arn   = module.lambda.lambda_function_arn
  lambda_function_name  = module.lambda.lambda_function_name
}

module "lambda" {
  source = "./modules/lambda"

  region                                = var.region
  email_dist_list                       = var.email_dist_list
  source_email                          = var.source_email
  application_error_metric_namespace    = var.application_error_metric_namespace
  container_restart_approved_alarm_names = join("|", flatten([
    for k, m in module.cloudwatch_alarms : m.alarm_names
  ]))
  env         = var.env
  secret_name = var.secret_name
}