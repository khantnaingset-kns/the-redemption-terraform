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

resource "aws_iam_policy" "logging_s3_access" {
  name        = "LoggingS3AccessPolicy"
  description = "Policy for granting access to S3 bucket for logging."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
        ]
        Resource = [
          "${var.eks_logs_bucket_arn}",
          "${var.eks_logs_bucket_arn}/*"
        ]
      }
    ]
  })
}
