module "sns_topic_alarm" {
  source = "terraform-aws-modules/sns/aws"
  name   = "${var.name}-alarms"

  subscriptions = {
    lambda = {
      protocol = "lambda"
      endpoint = var.lambda_function_notification_arn
    }
  }
}