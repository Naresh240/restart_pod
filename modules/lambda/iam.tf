resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-cloudwatch-alert-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-cloudwatch-alert-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:DescribeMetricFilters",
          "logs:FilterLogEvents",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:SetAlarmState",
          "secretsmanager:GetSecretValue",
          "ses:SendEmail",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
