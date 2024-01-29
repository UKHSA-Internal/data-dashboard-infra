output "iam_cloud_watch_role_arn" {
  value = module.iam_cloud_watch_role.iam_role_arn
}

output "kinesis_firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.splunk.arn
}
