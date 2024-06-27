resource "aws_cloudwatch_metric_alarm" cloudfront_frontend_500_errors {
  provider = aws.us_east_1

  alarm_name          = "${local.prefix}-cloudfront-frontend-5xx-alarm"
  alarm_description   = "HTTP 5xx errors in the frontend Cloudfront distribution."
  alarm_actions       = [aws_sns_topic.cloudfront_alarms.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  dimensions = {
    DistributionId = module.cloudfront_front_end.cloudfront_distribution_id
    Region         = "us-east-1"
  }
  namespace   = "AWS/CloudFront"
  metric_name = "5xxErrorRate"
  statistic   = "Average"
}

resource "aws_cloudwatch_metric_alarm" cloudfront_frontend_400_errors {
  provider = aws.us_east_1

  alarm_name          = "${local.prefix}-cloudfront-frontend-4xx-alarm"
  alarm_description   = "HTTP 4xx errors in the frontend Cloudfront distribution."
  alarm_actions       = [aws_sns_topic.cloudfront_alarms.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  dimensions = {
    DistributionId = module.cloudfront_front_end.cloudfront_distribution_id
    Region         = "us-east-1"
  }
  namespace   = "AWS/CloudFront"
  metric_name = "4xxErrorRate"
  statistic   = "Average"
}
