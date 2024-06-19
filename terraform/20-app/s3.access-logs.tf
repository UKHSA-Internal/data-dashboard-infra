data "aws_s3_bucket" "s3_access_logs" {
  bucket = "uhd-aws-s3-access-logs-${local.account_id}-${local.region}"
}
