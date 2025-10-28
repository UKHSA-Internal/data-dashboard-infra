locals {
  db_scale_up_cron_expression   = "cron(30 07 ? * MON-FRI *)"
  db_scale_down_cron_expression = "cron(10 20 ? * MON-FRI *)"
}

module "eventbridge_scheduled_scaling" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.2.2"
  create  = local.is_scaled_down_overnight

  create_bus         = false
  create_role        = true
  role_name          = "${local.prefix}-eventbridge-scheduled-scaling-role"
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds:StopDBCluster",
          "rds:StartDBCluster",
        ],
        Resource = [
          module.aurora_db_app.cluster_arn,
          module.aurora_db_feature_flags.cluster_arn,
        ]
      }
    ]
  })

  schedules = {
    # Scale up actions
    "${local.prefix}-start-app-db" = {
      schedule_expression      = local.db_scale_up_cron_expression
      timezone                 = local.timezone_london
      use_flexible_time_window = false
      arn                      = "arn:aws:scheduler:::aws-sdk:rds:startDBCluster"
      input = jsonencode({ DbClusterIdentifier = module.aurora_db_app.cluster_id })
    }
    "${local.prefix}-start-feature-flags-db" = {
      schedule_expression      = local.db_scale_up_cron_expression
      timezone                 = local.timezone_london
      use_flexible_time_window = false
      arn                      = "arn:aws:scheduler:::aws-sdk:rds:startDBCluster"
      input = jsonencode({ DbClusterIdentifier = module.aurora_db_feature_flags.cluster_id })
    }

    # Scale down actions
    "${local.prefix}-stop-app-db" = {
      schedule_expression      = local.db_scale_down_cron_expression
      timezone                 = local.timezone_london
      use_flexible_time_window = false
      arn                      = "arn:aws:scheduler:::aws-sdk:rds:stopDBCluster"
      input = jsonencode({ DbClusterIdentifier = module.aurora_db_app.cluster_id })
    }
    "${local.prefix}-stop-feature-flags-db" = {
      schedule_expression      = local.db_scale_down_cron_expression
      timezone                 = local.timezone_london
      use_flexible_time_window = false
      arn                      = "arn:aws:scheduler:::aws-sdk:rds:stopDBCluster"
      input = jsonencode({ DbClusterIdentifier = module.aurora_db_feature_flags.cluster_id })
    }
  }
}

