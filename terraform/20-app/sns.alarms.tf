module "sns_topic_alarms" {
  source  = "terraform-aws-modules/sns/aws"
  name    = "${local.prefix}-alarms"
  version = "6.2.0"

  subscriptions = {
    lambda = {
      protocol = "lambda"
      endpoint = module.lambda_alarm_notification.lambda_function_arn
    }
  }
}