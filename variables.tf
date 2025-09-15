# -------------------------------
# Environment & AWS settings
# -------------------------------
variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
}

# --------------------------
# SNS & Lambda integration
# --------------------------

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

variable "secret_name" {
  description = "Secrets Manager secret name for SES credentials"
  type        = string
}

# -------------------------------
# CloudWatch log groups & patterns
# -------------------------------
variable "app_log_groups" {
  description = "List of log groups for application monitoring"
  type        = list(string)
  default     = []
}

variable "app_log_pattern" {
  description = "Pattern to match in app logs (default = ERROR)"
  type        = string
  default     = null
}

variable "mariadb_log_groups" {
  description = "List of log groups for MariaDB monitoring"
  type        = list(string)
  default     = []
}

variable "mariadb_log_pattern" {
  description = "Pattern to match in MariaDB logs (default = unableToConnectToDB)"
  type        = string
  default     = null
}