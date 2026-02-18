module "sns_topic_alarms" {
  source = "terraform-aws-modules/sns/aws"
  version = "7.1.0"
  name   = "${local.prefix}-alarms"

  subscriptions = {
    lambda = {
      protocol = "lambda"
      endpoint = module.lambda_alarm_notification.lambda_function_arn
    }
  }
}
