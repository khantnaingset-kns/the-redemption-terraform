resource "aws_kms_key" "logs_bucket_kms_key" {
  description             = "KMS key for encrypting VPC Flow Logs"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.vpc_name}-flow-logs-kms-key"
  }
}

resource "aws_kms_key_policy" "logs_bucket_kms_key" {
  key_id = aws_kms_key.logs_bucket_kms_key.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "logs-bucket-kms-key-policy"

    Statement = concat(
      [
        {
          Sid    = "EnableIAMPolicyDelegation"
          Effect = "Allow"

          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"
          }

          Action   = "kms:*"
          Resource = "*"
        },
        {
          Sid    = "AllowVPCFlowLogsDeliveryToUseKey"
          Effect = "Allow"

          Principal = {
            Service = "delivery.logs.amazonaws.com"
          }

          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]

          Resource = "*"

          Condition = {
            StringEquals = {
              "aws:SourceAccount" = data.aws_caller_identity.this.account_id
            }

            ArnLike = {
              "aws:SourceArn" = "arn:aws:logs:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:*"
            }
          }
        }
      ],
      length(var.kms_admin_principal_arns) > 0 ? [
        {
          Sid    = "AllowKeyAdministration"
          Effect = "Allow"

          Principal = {
            AWS = var.kms_admin_principal_arns
          }

          Action = [
            "kms:Create*",
            "kms:Describe*",
            "kms:Enable*",
            "kms:List*",
            "kms:Put*",
            "kms:Update*",
            "kms:Revoke*",
            "kms:Disable*",
            "kms:Get*",
            "kms:Delete*",
            "kms:TagResource",
            "kms:UntagResource",
            "kms:ScheduleKeyDeletion",
            "kms:CancelKeyDeletion",
            "kms:RotateKeyOnDemand"
          ]

          Resource = "*"
        }
      ] : []
    )
  })
}

resource "aws_kms_alias" "logs_bucket_kms_key_alias" {
  name          = "alias/${var.environment}-flow-logs-kms-key"
  target_key_id = aws_kms_key.logs_bucket_kms_key.id
}
