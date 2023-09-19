data "aws_s3_bucket" "cloud_front_logs_eu_west_2" {
  bucket = "uhd-aws-cloud-front-access-logs-${local.account_id}-${local.region}"
}
