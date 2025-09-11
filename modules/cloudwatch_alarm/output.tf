output "cloudwatch_alarm_arn" {
    value = aws_lambda_function.alarm_handler.arn
}
