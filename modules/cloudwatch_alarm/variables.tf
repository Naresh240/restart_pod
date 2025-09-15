variable "env" {
  description = "Environment (dev, qa, prod)"
  type        = string
}

variable "log_groups" {
  description = "List of log groups to monitor"
  type        = list(string)
}

variable "pattern" {
  description = "Log filter pattern"
  type        = string
}

variable "namespace" {
  description = "CloudWatch metric namespace"
  type        = string
}

variable "prefix" {
  description = "Prefix for metric and filter names"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
}