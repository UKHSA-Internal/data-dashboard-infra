locals {
  s3_ingest_bucket_name = "${local.prefix}-ingest"
}

module "s3_ingest" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = local.s3_ingest_bucket_name

  attach_deny_insecure_transport_policy = true
  force_destroy                         = true

  logging = {
    target_bucket = data.aws_s3_bucket.s3_access_logs.id
    target_prefix = "${local.s3_ingest_bucket_name}/"
  }

  lifecycle_rule = [
    {
      id      = "processed"
      enabled = true
      filter = {
        prefix = "processed/"
      }
      expiration = {
        days = 30
      }
    },
    {
      id      = "failed"
      enabled = true
      filter = {
        prefix = "failed/"
      }
      expiration = {
        days = 14
      }
    }
  ]
}

module "s3_ingest_notification" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "4.1.2"

  bucket = module.s3_ingest.s3_bucket_id

  lambda_notifications = {
    lambda_ingestion = {
      function_arn  = module.lambda_producer.lambda_function_arn
      function_name = module.lambda_producer.lambda_function_name
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "in/"
      filter_suffix = ".json"
    }
  }
}
