resource "aws_cloudwatch_metric_stream" "all_metrics" {
  count = var.create ? 1 : 0

  name          = "all-metrics-to-splunk"
  role_arn      = module.iam_cloud_watch_role.iam_role_arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.splunk[0].arn
  output_format = "json"
}

resource "aws_cloudwatch_log_group" "splunk" {
  count = var.create ? 1 : 0

  name = "/aws/kinesisfirehose/splunk-cloud-watch-metrics"
}

resource "aws_cloudwatch_log_stream" "splunk" {
  count = var.create ? 1 : 0

  name           = "DestinationDelivery"
  log_group_name = aws_cloudwatch_log_group.splunk[0].name
}
