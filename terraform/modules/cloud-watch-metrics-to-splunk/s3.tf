module "s3_kinesis_backup" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"

  bucket = "splunk-cw-metrics-kinesis-backup-${local.account_id}-${local.region}"

  attach_deny_insecure_transport_policy = true
  force_destroy                         = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_splunk.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
