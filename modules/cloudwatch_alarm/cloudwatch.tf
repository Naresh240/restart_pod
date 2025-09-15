locals {
  log_group_map = {
    for lg in flatten([
      for lg_name in var.log_groups : [{
        log_group = lg_name
        prefix    = var.prefix
        namespace = var.namespace
        pattern   = var.pattern
      }]
    ]) :
    "${var.prefix}${replace(lg.log_group, "/", "-")}" => lg
  }
}

resource "aws_cloudwatch_log_metric_filter" "filters" {
  for_each       = local.log_group_map

  name           = "${each.value.prefix}Filter${replace(each.value.log_group, "/", "-")}-${var.env}"
  log_group_name = each.value.log_group
  pattern        = each.value.pattern

  metric_transformation {
    name      = "${each.value.prefix}${replace(each.value.log_group, "/", "-")}-${var.env}"
    namespace = each.value.namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarms" {
  for_each = aws_cloudwatch_log_metric_filter.filters

  alarm_name          = each.value.metric_transformation[0].name
  alarm_description   = "Error > 0 in log group ${each.value.log_group_name} (${var.env})"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_name = each.value.metric_transformation[0].name
  namespace   = each.value.metric_transformation[0].namespace
  period      = 60
  statistic   = "Sum"
}
