module "lambda_producer" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.21.0"
  function_name = "${local.prefix}-producer"
  description   = "Acts as the conduit between the S3 ingest bucket and the Kinesis data stream."

  cloudwatch_logs_retention_in_days = local.default_log_retention_in_days

  create_package = true
  runtime        = "nodejs18.x"
  handler        = "index.handler"
  source_path    = "../../src/lambda-producer-handler"

  maximum_retry_attempts = 1
  timeout                = 60 # Timeout after 1 minute

  architectures = ["arm64"]

  environment_variables = {
    KINESIS_DATA_STREAM_NAME = aws_kinesis_stream.kinesis_data_stream_ingestion.name
  }

  attach_policy_statements = true
  policy_statements = {
    get_items_from_in_folder_of_ingest_bucket = {
      actions   = ["s3:GetObject"]
      effect    = "Allow"
      resources = ["${module.s3_ingest.s3_bucket_arn}/in/*"]
    }
    write_to_kinesis = {
      effect    = "Allow"
      actions   = ["kinesis:PutRecord"]
      resources = [aws_kinesis_stream.kinesis_data_stream_ingestion.arn]
    }
  }
}
