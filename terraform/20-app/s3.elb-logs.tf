data "aws_s3_bucket" "elb_logs_eu_west_2" {
  bucket = "uhd-aws-elb-access-logs-${local.account_id}-${local.region}"
}
