data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_files/lambda.py"
  output_path = "${path.module}/lambda_files/lambda_function.zip"
}

resource "aws_lambda_function" "alarm_handler" {
  function_name    = "cloudwatch-alarm-handler"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 120

  environment {
    variables = {
      region                             = var.region
      email_dist_list                    = var.email_dist_list
      source_email                       = var.source_email
      application_error_metric_namespace = var.application_error_metric_namespace
      env                                = var.env
      container_restart_approved_alarm_names = var.container_restart_approved_alarm_names
      high_priority_prefix               = "[HIGH]"
      secret_name                        = var.secret_name
    }
  }
}