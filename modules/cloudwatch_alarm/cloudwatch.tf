data "aws_cloudwatch_log_metric_filter" "metric_filters" {
  for_each       = var.metric_filters
  name           = each.value
  log_group_name = each.key
}

resource "aws_cloudwatch_metric_alarm" "app_error_alarms" {
  for_each            = aws_cloudwatch_log_metric_filter.error_filters
  alarm_name          = "App-ErrorCount-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = each.value.metric_transformation[0].name
  namespace           = each.value.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Application Error Count > 0 in ${each.key}"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  depends_on = [aws_cloudwatch_log_metric_filter.error_filters]
}