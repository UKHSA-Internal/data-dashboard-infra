resource "aws_s3_bucket" "audit_logs" {
  bucket = "${local.prefix}-audit-logs"
}

resource "aws_s3_bucket_versioning" "audit_logs_versioning" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs_lifecycle" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "audit-retention-policy"
    status = "Enabled"
    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    # Delete items after 7 years
    expiration {
      days = 2555
    }

    noncurrent_version_expiration {
      noncurrent_days = 2555
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads-rule"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {}
  }
}
