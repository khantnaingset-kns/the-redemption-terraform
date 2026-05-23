resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket_namespace = "account-regional"
  bucket           = format("%s-%s-%s-bucket", data.aws_caller_identity.this.account_id, data.aws_region.this.name, var.vpc_flow_logs_bucket_prefix)
}

resource "aws_s3_bucket_ownership_controls" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    id     = "vpc-flow-logs-retention"
    status = "Enabled"

    filter {
      prefix = "AWSLogs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = var.vpc_flow_logs_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.logs_bucket_kms_key_arn
    }

    bucket_key_enabled = true
  }
}


resource "aws_s3_bucket" "eks_logs" {
  bucket_namespace = "account-regional"
  bucket           = format("%s-%s-%s-bucket", data.aws_caller_identity.this.account_id, data.aws_region.this.name, var.eks_logs_bucket_prefix)
}

resource "aws_s3_bucket_ownership_controls" "eks_logs" {
  bucket = aws_s3_bucket.eks_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "eks_logs" {
  bucket = aws_s3_bucket.eks_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "eks_logs" {
  bucket = aws_s3_bucket.eks_logs.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "eks_logs" {
  bucket = aws_s3_bucket.eks_logs.id

  rule {
    id     = "eks-logs-retention"
    status = "Enabled"

    filter {
      prefix = "AWSLogs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = var.vpc_flow_logs_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "eks_logs" {
  bucket = aws_s3_bucket.eks_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.logs_bucket_kms_key_arn
    }

    bucket_key_enabled = true
  }
}
