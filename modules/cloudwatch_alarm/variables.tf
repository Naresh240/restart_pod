variable "log_groups" {
  description = "List of log groups to monitor"
  type        = list(string)
}

variable "metric_filters" {
  type = map(string)
}

variable "sns_topic_arn" {
  type = string
}