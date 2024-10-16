module "cloudwatch_alarm_aurora_db_app" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.0"
  count   = local.needs_alarms ? 1 : 0

  alarm_name          = "${local.prefix}-aurora-db-app"
  alarm_description   = "CPU utilization of aurora db application cluster"
  alarm_actions       = [module.sns_topic_alarms.topic_arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 90
  period              = 60
  dimensions = {
    DBClusterIdentifier = module.aurora_db_app.cluster_id
  }
  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"
  statistic   = "Average"
}