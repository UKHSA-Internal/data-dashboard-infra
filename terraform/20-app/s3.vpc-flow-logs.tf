data "aws_s3_bucket" "vpc_flow_logs_eu_west_2" {
  bucket = "uhd-aws-vpc-flow-logs-${local.account_id}-${local.region}"
}
