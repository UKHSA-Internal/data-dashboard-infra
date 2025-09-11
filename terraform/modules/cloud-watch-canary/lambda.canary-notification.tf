module "lambda_canary_notification" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.0"
  create  = var.create

  function_name = "${var.name}-canary-notification"
  description   = "Sends notifications when a synthetics canary run fails."

  create_package = true
  runtime        = "nodejs18.x"
  handler        = "index.handler"
  source_path    = "../modules/cloud-watch-canary/src/lambda-canary-notification"

  timeout = 120

  architectures = ["arm64"]
  maximum_retry_attempts = 1

  environment_variables = {
    SECRETS_MANAGER_SLACK_WEBHOOK_URL_ARN = var.slack_webhook_url_secret_arn
    S3_CANARY_LOGS_BUCKET_NAME            = module.s3_canary_logs.s3_bucket_id
  }

  attach_policy_statements = true
  policy_statements = {
    get_screenshots_from_s3_bucket = {
      effect = "Allow"
      actions = ["s3:GetObject"]
      resources = ["${module.s3_canary_logs.s3_bucket_arn}/*"]
    }
    list_objects_in_s3_bucket = {
      effect = "Allow"
      actions = ["s3:ListBucket"]
      resources = [module.s3_canary_logs.s3_bucket_arn]
    }
    get_slack_webhook_url_from_secrets_manager = {
      effect = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = [var.slack_webhook_url_secret_arn]
    }
    get_recent_canary_runs = {
      effect = "Allow"
      actions = ["synthetics:GetCanaryRuns"]
      resources = [aws_synthetics_canary.this.arn]
    }
  }

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    eventbridge = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge_canary.eventbridge_rule_arns[var.name]
    }
  }
}


module "lambda_canary_notification_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "${var.name}-lambda-canary-notification"
  vpc_id = var.vpc_id

  egress_with_cidr_blocks = [
    {
      description = "https to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
