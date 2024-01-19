module "cloud_watch_metrics_to_splunk_eu_west_2" {
  source = "../modules/cloud-watch-metrics-to-splunk"

  create         = local.ship_cloud_watch_metrics_to_splunk
  kms_key_owners = ["arn:aws:iam::${var.tools_account_id}:root"]
  hec_endpoint   = jsondecode(data.aws_secretsmanager_secret_version.splunk_cloudwatch_metrics_token.secret_string)["endpoint"]
  hec_token      = jsondecode(data.aws_secretsmanager_secret_version.splunk_cloudwatch_metrics_token.secret_string)["token"]
  python_version = var.python_version
}

module "cloud_watch_metrics_to_splunk_us_east_1" {
  source = "../modules/cloud-watch-metrics-to-splunk"

  create         = local.ship_cloud_watch_metrics_to_splunk
  kms_key_owners = ["arn:aws:iam::${var.tools_account_id}:root"]
  hec_endpoint   = jsondecode(data.aws_secretsmanager_secret_version.splunk_cloudwatch_metrics_token.secret_string)["endpoint"]
  hec_token      = jsondecode(data.aws_secretsmanager_secret_version.splunk_cloudwatch_metrics_token.secret_string)["token"]
  python_version = var.python_version

  providers = {
    aws = aws.us_east_1
  }
}
