resource "aws_cloudwatch_log_metric_filter" "error_filters" {
  for_each       = toset(var.log_groups)
  name           = "ErrorFilter${replace(each.value, "/", "-")}"
  log_group_name = each.value
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "AppMonitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_error_alarm" {
  alarm_name          = "App-ErrorCount-All"
  alarm_description   = "Application Error Count > 0 across all log groups"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_name = "ErrorCount"
  namespace   = "AppMonitoring"
  period      = 60
  statistic   = "Sum"

  depends_on = [aws_cloudwatch_log_metric_filter.error_filters]
}