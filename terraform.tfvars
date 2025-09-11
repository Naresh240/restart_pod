region      = "us-east-1"

email_dist_list = "devops@example.com,ops@example.com"
source_email = "alerts@example.com"

application_error_metric_namespace = "AppMonitoring"
env                         = "dev"

container_restart_approved_alarm_names = "RestartAlarm1|RestartAlarm2"
high_priority_prefix = "[HIGH]"

secret_name = "my-ses-secret"

log_groups = [
  "/aws/eks/fluentbit-logs",
]

metric_filters = {
  "/app/log/group1" = "CustomFilter-group1"
  "/app/log/group2" = "CustomFilter-group2"
  "/app/log/group3" = "CustomFilter-group3"
}