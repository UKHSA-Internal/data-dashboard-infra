module "s3_access_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.7.0"

  bucket = "uhd-aws-s3-access-logs-${local.account_id}-${local.region}"

  attach_deny_insecure_transport_policy = true
  attach_access_log_delivery_policy     = true

  access_log_delivery_policy_source_accounts = [local.account_id]
  access_log_delivery_policy_source_buckets  = [
    "arn:aws:s3:::uhd-*-ingest",
    "arn:aws:s3:::uhd-*-archive-web-content",
  ]
}
