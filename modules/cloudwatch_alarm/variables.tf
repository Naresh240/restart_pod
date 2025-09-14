variable "log_groups" {
  description = "List of log groups to monitor"
  type        = list(string)
}

variable "sns_topic_arn" {
  type = string
}