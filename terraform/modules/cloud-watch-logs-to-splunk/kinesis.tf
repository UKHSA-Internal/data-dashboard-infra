resource "aws_kinesis_firehose_delivery_stream" "splunk" {
  name        = "splunk-cloud-watch-logs"
  destination = "splunk"

  splunk_configuration {
    hec_endpoint               = var.hec_endpoint
    hec_token                  = var.hec_token
    hec_acknowledgment_timeout = 600
    hec_endpoint_type          = "Event"
    s3_backup_mode             = "FailedEventsOnly"

    s3_configuration {
      bucket_arn         = module.s3_kinesis_backup.s3_bucket_arn
      buffering_interval = 400
      buffering_size     = 10
      compression_format = "GZIP"
      role_arn           = module.iam_kinesis_role.iam_role_arn
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.splunk.name
      log_stream_name = aws_cloudwatch_log_stream.splunk.name
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${module.lambda_processor.lambda_function_arn}:$LATEST"
        }

        parameters {
          parameter_name  = "RoleArn"
          parameter_value = module.iam_kinesis_role.iam_role_arn
        }
      }
    }

  }

  server_side_encryption {
    enabled  = true
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn  = module.kms_splunk.key_arn
  }
}
