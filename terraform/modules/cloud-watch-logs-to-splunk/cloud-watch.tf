resource "aws_cloudwatch_log_group" "splunk" {
  name = "/aws/kinesisfirehose/splunk-cloud-watch-logs"
}

resource "aws_cloudwatch_log_stream" "splunk" {
  name           = "DestinationDelivery"
  log_group_name = aws_cloudwatch_log_group.splunk.name
}
