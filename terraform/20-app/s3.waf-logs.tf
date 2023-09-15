data "aws_s3_bucket" "halo_waf_logs_eu_west_2" {
  bucket = "aws-waf-logs-halo-${local.account_id}-eu-west-2-wpr-${var.halo_account_type}-avm-bs-gr-r"
}

data "aws_s3_bucket" "halo_waf_logs_us_east_1" {
  bucket   = "aws-waf-logs-halo-${local.account_id}-us-east-1-wpr-${var.halo_account_type}-avm-bs-gr-r"
  provider = aws.us_east_1
}
