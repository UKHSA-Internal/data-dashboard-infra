module "lambda_alarm_notification" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.8.1"
  function_name = "${local.prefix}-alarm-notification"
  description   = "Sends notifications when Cloudwatch alarms from key services are raised."

  create_package = true
  runtime        = "nodejs18.x"
  handler        = "index.handler"
  source_path    = "../../src/lambda-alarm-notification"

  architectures          = ["arm64"]
  maximum_retry_attempts = 1

  environment_variables = {
    SECRETS_MANAGER_SLACK_WEBHOOK_URL_ARN = aws_secretsmanager_secret.slack_webhook_url.arn
  }

  attach_policy_statements = true
  policy_statements = {
    subscribe_to_sns_for_alarms = {
      actions   = ["sns:Subscribe", "sns:Receive"]
      effect    = "Allow"
      resources = [
        aws_sns_topic.cloudfront_alarms.arn,
        module.sns_topic_alarms.topic_arn,
      ]
    }
    get_slack_webhook_url_from_secrets_manager = {
      effect    = "Allow",
      actions   = ["secretsmanager:GetSecretValue"],
      resources = [aws_secretsmanager_secret.slack_webhook_url.arn]
    }
  }

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    sns_cloudfront_alarms = {
      principal  = "sns.amazonaws.com"
      source_arn = aws_sns_topic.cloudfront_alarms.arn
    }
    sns_aurora_db_alarms = {
      principal  = "sns.amazonaws.com"
      source_arn = module.sns_topic_alarms.topic_arn
    }
  }
}

module "lambda_alarm_notification_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name   = "${local.prefix}-lambda-alarm-notification"
  vpc_id = module.vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      description = "https to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
