module "cloudwatch_alarm_cloudfront_frontend_500_errors" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.4.0"

  alarm_name          = "${local.prefix}-cloudfront-frontend-5xx-alarm"
  alarm_description   = "HTTP 5xx errors in the frontend Cloudfront distribution."
  alarm_actions       = [module.sns_topic_alarms.topic_arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  unit                = "None"
  dimensions = {
    DistributionId = module.cloudfront_front_end.cloudfront_distribution_id
    Region         = "us-east-1"
  }
  namespace   = "AWS/CloudFront"
  metric_name = "5xxErrorRate"
  statistic   = "Average"
}

module "cloudwatch_alarm_cloudfront_frontend_400_errors" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.4.0"

  alarm_name          = "${local.prefix}-cloudfront-frontend-4xx-alarm"
  alarm_description   = "HTTP 4xx errors in the frontend Cloudfront distribution."
  alarm_actions       = [module.sns_topic_alarms.topic_arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  unit                = "None"
  dimensions = {
    DistributionId = module.cloudfront_front_end.cloudfront_distribution_id
    Region         = "us-east-1"
  }
  namespace   = "AWS/CloudFront"
  metric_name = "4xxErrorRate"
  statistic   = "Average"
}

module "cloudwatch_alarm_aurora_db_app" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.4.0"

  alarm_name          = "${local.prefix}-aurora-db-app"
  alarm_description   = "CPU utilization of aurora db application cluster"
  alarm_actions       = [module.sns_topic_alarms.topic_arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 90
  period              = 60
  unit                = "None"
  dimensions = {
    DBClusterIdentifier = module.aurora_db_app.cluster_id
  }
  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"
  statistic   = "Average"
}
