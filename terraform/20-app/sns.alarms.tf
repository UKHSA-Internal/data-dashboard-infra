module "sns_topic_alarms" {
  source = "terraform-aws-modules/sns/aws"
  name   = "${local.prefix}-alarms"

  subscriptions = {
    lambda = {
      protocol = "lambda"
      endpoint = module.lambda_alarm_notification.lambda_function_arn
    }
  }
}