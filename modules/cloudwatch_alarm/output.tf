output "metric_filter_names" {
  description = "List of metric filter names created"
  value       = [for f in aws_cloudwatch_log_metric_filter.filters : f.name]
}

output "alarm_names" {
  description = "List of metric alarm names created"
  value       = [for a in aws_cloudwatch_metric_alarm.alarms : a.alarm_name]
}