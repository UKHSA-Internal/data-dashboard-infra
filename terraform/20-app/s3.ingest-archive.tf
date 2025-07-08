module "s3_ingest_archive" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.2.0"

  bucket = "${local.s3_ingest_bucket_name}-archive"

  attach_deny_insecure_transport_policy = true
  force_destroy                         = true

  versioning = {
    status     = true
    mfa_delete = false
  }

  logging = {
    target_bucket = data.aws_s3_bucket.s3_access_logs.id
    target_prefix = "${local.s3_ingest_bucket_name}-archive/"
  }

  lifecycle_rule = [
    {
      id      = "archive"
      enabled = true
      filter = {
        prefix = ""
      }
      transition = {
        days          = 0
        storage_class = "GLACIER_IR"
      }
    },
  ]
}
