resource "aws_sns_topic" "cloudwatch_alarm_topic" {
  name = "trigger-k8s-lambda-topic"
}

resource "aws_lambda_permission" "sns_invoke_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_alarm_topic.arn
}

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.cloudwatch_alarm_topic.arn
  protocol  = "lambda"
  endpoint  = var.lambda_function_arn
}