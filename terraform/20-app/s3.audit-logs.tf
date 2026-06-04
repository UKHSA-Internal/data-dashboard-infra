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
      abort_incomplete_multipart_upload_days = 7
    }
  ]
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

  lifecycle_rule = [
    {
      id      = "audit-access-retention-policy"
      enabled = true
      filter = {
        prefix = ""
      }
      transition = {
        days          = 90
        storage_class = "GLACIER"
      }
      expiration = {
        days = 365
      }
      noncurrent_version_expiration = {
        noncurrent_days = 365
      }
      abort_incomplete_multipart_upload_days = 7
    }
  ]
}
