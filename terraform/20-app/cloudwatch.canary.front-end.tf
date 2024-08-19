module "cloudwatch_canary_front_end_screenshots" {
  source            = "../modules/cloud-watch-canary"
  create            = true
  name              = "${local.prefix}-display"
  s3_access_logs_id = data.aws_s3_bucket.s3_access_logs.id
  s3_logs_destination = {
    bucket_id  = module.s3_canary_logs.s3_bucket_id
    bucket_arn = module.s3_canary_logs.s3_bucket_arn
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  schedule_expression               = "rate(10 minutes)"
  timeout_in_seconds                = 600
  src_script_path                   = "canary-front-end-broken-links"
  lambda_function_notification_arn  = module.lambda_canary_notification.lambda_function_arn
  lambda_function_notification_name = module.lambda_canary_notification.lambda_function_name

  environment_variables = {
    SITEMAP_URL = "${local.urls.front_end}/sitemap.xml"
  }
}
