output "alarm_names" {
  description = "List of CloudWatch alarm names created for each log group."
  value       = [for alarm in aws_cloudwatch_metric_alarm.app_error_alarms : alarm.alarm_name]
}