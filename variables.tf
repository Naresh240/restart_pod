variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "email_dist_list" {
  description = "Comma separated distribution list for alerts"
  type        = string
}

variable "source_email" {
  description = "SES verified source email address"
  type        = string
}

variable "application_error_metric_namespace" {
  description = "Namespace for application error metrics"
  type        = string
}

variable "env" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
}

variable "secret_name" {
  description = "Secrets Manager secret name for SES credentials"
  type        = string
}

variable "log_groups" {
  description = "List of existing log groups to monitor"
  type        = list(string)
}
