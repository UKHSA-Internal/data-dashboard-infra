module "s3_audit_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket = "${local.prefix}-audit-logs"

  attach_deny_insecure_transport_policy = true
  force_destroy                         = true

  lifecycle_rule = [
    {
      id      = "audit-retention-policy"
      enabled = true
      filter = {
        prefix = ""
      }
      transition = {
        days          = 365
        storage_class = "GLACIER"
      }
      expiration = {
        days = 2555
      }
      noncurrent_version_expiration = {
        noncurrent_days = 2555
      }
    },
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_audit_logs.s3_bucket_arn,
          "${module.s3_audit_logs.s3_bucket_arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

module "s3_audit_logs_access_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket = "${local.prefix}-audit-logs-access-logs"

  attach_deny_insecure_transport_policy = true
  attach_access_log_delivery_policy     = true
  force_destroy                         = true

  access_log_delivery_policy_source_accounts = [local.account_id]
  access_log_delivery_policy_source_buckets  = [module.s3_audit_logs.s3_bucket_arn]
}


# resource "aws_s3_bucket_versioning" "audit_logs_versioning" {
#   bucket = aws_s3_bucket.audit_logs.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_lifecycle_configuration" "audit_logs_lifecycle" {
#   bucket = aws_s3_bucket.audit_logs.id

#   rule {
#     id     = "audit-retention-policy"
#     status = "Enabled"
#     transition {
#       days          = 365
#       storage_class = "GLACIER"
#     }

#     # Delete items after 7 years
#     expiration {
#       days = 2555
#     }

#     noncurrent_version_expiration {
#       noncurrent_days = 2555
#     }
#   }

#   rule {
#     id     = "abort-incomplete-multipart-uploads-rule"
#     status = "Enabled"

#     abort_incomplete_multipart_upload {
#       days_after_initiation = 7
#     }

#     filter {}
#   }
# }
