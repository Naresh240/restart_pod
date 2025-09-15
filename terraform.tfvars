# -------------------------------
# Environment & AWS settings
# -------------------------------
region      = "us-east-1"
env         = "dev"

# -------------------------------
# SNS + Lambda integration
# -------------------------------
email_dist_list = "devops@example.com,ops@example.com"
source_email = "alerts@example.com"
application_error_metric_namespace = "AppMonitoring"
secret_name = "my-ses-secret"

# ---------------------------------
# CloudWatch log groups & patterns
# ---------------------------------
app_log_pattern = null
mariadb_log_pattern = null
app_log_groups = [
  "/aws/eks/fluentbit-logs",
  "/aws/eks/fluentbit-logs1",
]

mariadb_log_groups = [
  "/aws/eks/fluentbit-mariadb-logs"
]