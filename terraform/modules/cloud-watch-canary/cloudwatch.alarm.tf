module "cloudwatch_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.3.1"

  alarm_name          = "${var.name}-failed-alarm"
  alarm_description   = jsonencode(
    {
      "description": "Alarm for SNS",
      "s3_prefix": "canary/eu-west-2/${var.name}"
    }
  )
  alarm_actions       = [module.sns_topic_alarm.topic_arn]
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 99
  period              = var.timeout_in_seconds
  dimensions = {
    CanaryName = aws_synthetics_canary.this.name
  }
  namespace   = "CloudWatchSynthetics"
  metric_name = "SuccessPercent"
  statistic   = "Sum"
}
