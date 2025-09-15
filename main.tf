module "lambda" {
  source = "./modules/lambda"


  region                                = var.region
  email_dist_list                       = var.email_dist_list
  source_email                          = var.source_email
  application_error_metric_namespace    = var.application_error_metric_namespace
  container_restart_approved_alarm_names= join("|", module.cloudwatch_alarm.alarm_names)
  env                                   = var.env
  secret_name                           = var.secret_name
}

module "cloudwatch_alarm" {
  source  = "./modules/cloudwatch_alarm"

  log_groups      = var.log_groups
  sns_topic_arn   = module.sns.sns_topic_arn
}

module "sns" {
  source  = "./modules/sns"

  lambda_function_arn   = module.lambda.lambda_function_arn
  lambda_function_name  = module.lambda.lambda_function_name
}