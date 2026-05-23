resource "aws_iam_policy" "fargate_cloudwatch_logs_policy" {
  name        = "fargate-cloudwatch-logs"
  description = "Allow Fargate pods to write to CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:PutRetentionPolicy"
        ],
        Resource = "*"
      }
    ]
  })
}
