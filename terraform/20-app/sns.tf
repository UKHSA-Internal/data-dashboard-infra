resource "aws_sns_topic" "sns_topic_alarms" {
  name   = "${local.prefix}-alarms"
  provider = aws.us_east_1
}

resource "aws_sns_topic_subscription" "this" {
  provider = aws.us_east_1
  endpoint = module.lambda_alarm_notification.lambda_function_arn
  protocol = "lambda"
  topic_arn = aws_sns_topic.sns_topic_alarms.arn
}
