module "cloudwatch_canary_front_end_screenshots" {
  source = "../modules/cloud-watch-canary"
  name   = "${local.prefix}-display"

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnets
  s3_access_logs_id = data.aws_s3_bucket.s3_access_logs.id

  schedule_expression = "rate(5 minutes)"
  timeout_in_seconds  = 60 * 5
  src_script_filename = "canary-front-end-broken-links"

  environment_variables = {
    SITEMAP_URL = "${local.urls.front_end}/sitemap.xml"
  }

  slack_webhook_url_secret_arn = aws_secretsmanager_secret.slack_webhook_url.arn
}
