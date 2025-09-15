region      = "us-east-1"

email_dist_list = "devops@example.com,ops@example.com"
source_email = "alerts@example.com"

application_error_metric_namespace = "AppMonitoring"

env                         = "dev"

secret_name = "my-ses-secret"

log_groups = [
  "/aws/eks/fluentbit-logs",
  "/aws/eks/fluentbit-logs1",
]
