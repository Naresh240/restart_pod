output "lambda_function_arn" {
    value = aws_lambda_function.alarm_handler.arn
}

output "lambda_function_name" {
    value = aws_lambda_function.alarm_handler.function_name
}