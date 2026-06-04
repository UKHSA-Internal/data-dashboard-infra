resource "aws_kinesis_firehose_delivery_stream" "audit_stream" {
  name        = "${local.prefix}-audit-log-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = module.s3_audit_logs.s3_bucket_arn
    
    # Deliver every 5MB or every 5 minutes (whichever comes first)
    buffering_size = 5
    buffering_interval = 300

    prefix = "compliance/audit_year=!{timestamp:yyyy}/month=!{timestamp:MM}/"
    error_output_prefix = "errors/"
  }
}
