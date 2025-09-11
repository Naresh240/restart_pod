import os
import json
import re
from datetime import datetime, timedelta
from urllib import request as urls
import boto3

# -----------------------
# Load environment variables
# -----------------------
region = os.environ['region']
email_dist_list = os.environ['email_dist_list'].split(",")
source_email = os.environ['source_email']
application_error_metric_ns = os.environ['application_error_metric_namespace'].split("|")
env = os.environ["env"]
container_restart_approved_alarm_names = os.environ["container_restart_approved_alarm_names"].split("|")
high_priority_prefix_text = os.environ["high_priority_prefix"]
secret_name = os.environ["secret_name"]

stored_proc_mapping = {
    "preference_data_denormalization_" + env: "usp_preference_data_denormalization",
    "preference_fetch_denormalization_" + env: "usp_preference_data_denormalization_fetch"
}

approved_alarms_list = container_restart_approved_alarm_names
log_stream = None

cloudwatch = boto3.client('cloudwatch')
cloudwatch_logs = boto3.client('logs')


# -----------------------
# Secret fetch
# -----------------------
def get_api_token(secret_name):
    """
    Fetches the API_TOKEN value from a given Secrets Manager secret
    """
    client = boto3.client('secretsmanager')
    try:
        secret_value = client.get_secret_value(SecretId=secret_name)['SecretString']
        secret_dict = json.loads(secret_value)
        api_token = secret_dict.get('API_TOKEN')
        if not api_token:
            raise ValueError(f"API_TOKEN not found in secret {secret_name}")
        return api_token
    except Exception as e:
        print(f"[#ERROR#] Failed to fetch API token from secret {secret_name}: {e}")
        return None


# -----------------------
# Email helpers
# -----------------------
def send_email(subject, text):
    aws_region = os.environ.get('AWS_REGION', 'us-east-1')
    ses = boto3.client('ses', region_name=aws_region)
    try:
        ses.send_email(
            Source=source_email,
            Destination={'BccAddresses': email_dist_list},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Html': {'Data': text}}
            }
        )
    except Exception as e:
        print(f"[#ERROR#]: Error occurred while Sending Email: {str(e)}")


def get_alarm_table(message):
    datetimeObj = datetime.strptime(message['StateChangeTime'], '%Y-%m-%dT%H:%M:%S.%f%z')
    alarm_description = message.get('AlarmDescription', 'Not Available')
    aws_account_id = message.get('AWSAccountId', 'N/A')  # <- fix here
    return f"""
    <table border="1" style="font-family: arial, sans-serif; font-size: 11px; border-collapse: collapse;">
        <tr><th>Alarm Name</th><td>{message['AlarmName']}</td></tr>
        <tr><th>Alarm Description</th><td>{alarm_description}</td></tr>
        <tr><th>Alarm Time (UTC)</th><td>{datetimeObj.strftime('%d-%b-%Y %H:%M:%S')} UTC</td></tr>
        <tr><th>AWS Region</th><td>{message.get('Region', 'N/A')}</td></tr>
        <tr><th>AWS Account ID</th><td>{aws_account_id}</td></tr>
    </table>
    """

# -----------------------
# Metric email content
# -----------------------
def prepare_email_content(message, data):
    style = "<style> pre {color: red; font-family: arial, sans-serif; font-size: 11px;} </style>"
    html = '<br/><b><u>Metric Details:</u></b><br/><br/>' + style
    html += '<pre><b>Metric Namespace: </b>' + message['Trigger']['Metric']['Namespace'] + '</pre>'
    html += '<pre><b>Metric Name</b>: ' + message['Trigger']['Metric']['MetricName'] + '</pre>'
    stored_proc_key = message['Trigger']['Metric']['Dimensions'][0]['value']
    proc_name = stored_proc_mapping.get(stored_proc_key, "N/A")
    html += f'<pre><b>Stored procedure Name: </b>{proc_name}</pre><br>'

    if data:
        html += """<table border='1' style="font-family: arial, sans-serif; font-size: 11px; border-collapse: collapse; width: auto;">"""
        column_headers = list(data[0].keys())
        html += '<tr>'
        for header in column_headers:
            display_header = 'Record #' if header == 'SampleCount' else header
            html += f'<th style="border: 1px solid #dddddd; text-align: center; padding: 8px;">{display_header}</th>'
        html += '</tr>'

        for row in data:
            html += '<tr>'
            for header in column_headers:
                val = row.get(header)
                if header in ['Average', 'Minimum', 'Maximum'] and val is not None:
                    val = round(val, 2)
                if header == 'SampleCount' and val is not None:
                    val = int(val)
                html += f'<td style="border: 1px solid #dddddd; text-align: center; padding: 8px;">{val}</td>'
            html += '</tr>'
        html += '</table>'

    html += f"<br><u><b>Source Identifier: </b></u> {log_stream}"
    return html


# -----------------------
# Error log processing
# -----------------------
def prepare_email_content_for_error_logs(response, message, log_group_name):
    events = response.get('events', [])
    subject = f"Details for Alarm - {message['AlarmName']}"
    alarm_table_html = get_alarm_table(message)

    aws_region = os.environ.get('AWS_REGION', 'us-east-1')
    console_url = f'https://{aws_region}.console.aws.amazon.com/cloudwatch/home?region={aws_region}#logsV2:log-groups/log-group/{log_group_name.replace("/", "$252F")}'

    style = "<style> pre {color: red; font-family: arial, sans-serif; font-size: 11px;} </style>"
    log_data = f'<br/><b><u>Log Details:</u></b><br/><br/>{style}'

    for event in events:
        log_stream_name = event['logStreamName']
        raw_message = event['message']

        # Try JSON parse
        pod_name, namespace = "N/A", "N/A"
        try:
            msg = json.loads(raw_message)
            pod_name = msg.get("kubernetes", {}).get("pod_name") or msg.get("pod") or "N/A"
            namespace = msg.get("kubernetes", {}).get("namespace_name") or msg.get("namespace") or "N/A"
        except Exception:
            msg = raw_message
            pod_match = re.search(r'pod[=: ]+([\w-]+)', raw_message)
            ns_match = re.search(r'namespace[=: ]+([\w-]+)', raw_message)
            if pod_match:
                pod_name = pod_match.group(1)
            if ns_match:
                namespace = ns_match.group(1)

        log_data += f'<pre><b>Log Group</b>: <a href="{console_url}/log-events/{log_stream_name}">{log_group_name}</a></pre>'
        log_data += f'<pre><b>Log Stream:</b> {log_stream_name}</pre>'
        log_data += f'<pre><b>K8s Namespace:</b> {namespace}</pre>'
        log_data += f'<pre><b>K8s Pod:</b> {pod_name}</pre>'
        log_data += f'<pre><b>Log Event:</b> {json.dumps(msg, indent=4) if isinstance(msg, dict) else msg}</pre><br/>'

        # Call API for pod restart
        if pod_name != "N/A" and namespace != "N/A":
            api_call(namespace, pod_name)

    send_email(subject, alarm_table_html + log_data)


# -----------------------
# Metric log processing
# -----------------------
def process_metric_data_for_error_logs(message, response):
    timestamp = message['StateChangeTime']
    datetimeObj = datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%S.%f%z')
    offset = (message['Trigger']['Period'] * message['Trigger']['EvaluationPeriods']) + 60

    start_time = datetimeObj - timedelta(seconds=offset)
    start_time_ms = int(start_time.timestamp() * 1000)
    end_time_ms = int(datetimeObj.timestamp() * 1000)

    metricFilter = response['metricFilters'][0]
    log_group_name = metricFilter['logGroupName']
    filter_pattern = metricFilter.get('filterPattern', '')

    response_fle = cloudwatch_logs.filter_log_events(
        logGroupName=log_group_name,
        startTime=start_time_ms,
        endTime=end_time_ms,
        filterPattern=filter_pattern
    )

    if response_fle.get('events'):
        prepare_email_content_for_error_logs(response_fle, message, log_group_name)
        if message['AlarmName'] in approved_alarms_list:
            reset_cw_alarm_state(message['AlarmName'])


def process_metric_data(message):
    timestamp = message['StateChangeTime']
    datetimeObj = datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%S.%f%z')
    offset = message['Trigger']['Period'] * message['Trigger']['EvaluationPeriods']
    start_time = datetimeObj - timedelta(seconds=offset)

    metric_dimensions = message['Trigger']['Dimensions'][0]
    dimensions = [{"Name": metric_dimensions["name"], "Value": metric_dimensions["value"]}]

    params = {
        'Namespace': message['Trigger']['Metric']['Namespace'],
        'MetricName': message['Trigger']['Metric']['MetricName'],
        'Dimensions': dimensions,
        'StartTime': start_time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'EndTime': datetimeObj.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'Period': message['Trigger']['Period'],
        'Statistics': ['SampleCount', 'Average', 'Minimum', 'Maximum']
    }

    response_get_metric_statistics = cloudwatch.get_metric_statistics(**params)
    sorted_dict_list = sorted(response_get_metric_statistics['Datapoints'], key=lambda d: d['Timestamp'])

    subject = f"Details for Alarm {message['AlarmName']}"
    alarm_table_html = get_alarm_table(message)
    metric_table_data = prepare_email_content(message, sorted_dict_list)
    text = alarm_table_html + metric_table_data

    send_email(subject, text)


# -----------------------
# Reset CloudWatch alarm state
# -----------------------
def reset_cw_alarm_state(alarm_name):
    cloudwatch_ucc_client = boto3.client('cloudwatch', region_name=region)
    try:
        response = cloudwatch_ucc_client.describe_alarms(AlarmNames=[alarm_name])
        state = response['MetricAlarms'][0]['StateValue']

        if state != "OK":
            cloudwatch_ucc_client.set_alarm_state(
                AlarmName=alarm_name,
                StateValue='OK',
                StateReason='Set manually after executing Lambda at ' + str(datetime.now()),
            )
    except Exception as e:
        print(f"[#ERROR#]: Error occurred while updating alarm state: {str(e)}")


# -----------------------
# API Call for Kubernetes Pod
# -----------------------
def api_call(namespace, pod_name):
    API_TOKEN = get_api_token(secret_name)
    if not API_TOKEN:
        print("API token not available, skipping API call.")
        return

    url = "https://E9B5394C935D1C475D717A30982604A1.gr7.us-east-1.eks.amazonaws.com/k8s-utils/v1/pods/delete"
    request_data = {"namespace": namespace, "podName": pod_name}
    json_data = json.dumps(request_data).encode('utf8')
    headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + API_TOKEN}
    req = urls.Request(url, data=json_data, headers=headers, method="POST")

    try:
        with urls.urlopen(req) as response:
            print(f"Success: status={response.getcode()}, response={response.read().decode('utf8')}")
    except Exception as e:
        print(f"Error: {e}")


# -----------------------
# Lambda handler
# -----------------------
def lambda_handler(event, context):
    global log_stream
    log_stream = context.log_stream_name
    print("Event is: {}".format(json.dumps(event)))
    message = json.loads(event['Records'][0]['Sns']['Message'])

    metric_name = message['Trigger']['MetricName']
    metric_namespace = message['Trigger']['Namespace']

    # Identify type of Alarm
    if metric_namespace in application_error_metric_ns:
        response = cloudwatch_logs.describe_metric_filters(
            metricName=metric_name,
            metricNamespace=metric_namespace
        )
        if response['metricFilters']:
            process_metric_data_for_error_logs(message, response)
        else:
            print(f"Metric {metric_name} in namespace {metric_namespace} not found.")
    elif metric_namespace == 'MariaDB':
        process_metric_data(message)
    else:
        print(f"This Metric for Namespace: {metric_namespace} is not configured for custom CW Emails.")

    return {'statusCode': 200, 'body': json.dumps('Lambda execution complete')}
