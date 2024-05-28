module "ecs_service_front_end" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.1"

  name                   = "${local.prefix}-front-end"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  cpu        = local.use_prod_sizing ? 2048 : 512
  memory     = local.use_prod_sizing ? 4096 : 1024
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling       = true
  desired_count            = local.use_prod_sizing ? 3 : 1
  autoscaling_min_capacity = local.use_prod_sizing ? 3 : 1
  autoscaling_max_capacity = local.use_prod_sizing ? 20 : 1

  autoscaling_scheduled_actions = local.use_prod_sizing ? {} : local.scheduled_scaling_policies_for_non_essential_envs

  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    front-end = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      cpu                                    = local.use_prod_sizing ? 2048 : 512
      memory                                 = local.use_prod_sizing ? 4096 : 1024
      essential                              = true
      readonly_root_filesystem               = false
      image                                  = "${module.ecr_front_end.repository_url}:latest-graviton"
      port_mappings                          = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "API_URL"
          value = local.urls.private_api
        },
        {
          name  = "UNLEASH_SERVER_API_URL"
          value = "${local.urls.feature_flags}/api"
        },
        {
          name  = "FEEDBACK_API_URL"
          value = local.urls.feedback_api
        },
        {
          name  = "PUBLIC_API_URL"
          value = local.urls.public_api
        }
      ]
      secrets = [
        {
          name      = "API_KEY"
          valueFrom = aws_secretsmanager_secret.private_api_key.arn
        },
        {
          name      = "GOOGLE_TAG_MANAGER_ID",
          valueFrom = "${aws_secretsmanager_secret.google_analytics_credentials.arn}:google_tag_manager_id::"
        },
        {
          name      = "UNLEASH_SERVER_API_TOKEN",
          valueFrom = "${aws_secretsmanager_secret.feature_flags_api_keys.arn}:client_api_key::"
        },
        {
          name      = "ESRI_API_KEY"
          valueFrom = aws_secretsmanager_secret.esri_api_key.arn
        },
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.front_end_alb.target_groups["${local.prefix}-front-end-tg"].arn
      container_name   = "front-end"
      container_port   = 3000
    }
  }

  tasks_iam_role_statements = [
    {
      actions = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      resources = ["*"]
    }
  ]
}

module "front_end_tasks_security_group_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  create_sg         = false
  security_group_id = module.ecs_service_front_end.security_group_id

  ingress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "TCP"
      source_security_group_id = module.front_end_alb_security_group.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "https to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "to api"
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_service_front_end" {
  count = local.ship_cloud_watch_logs_to_splunk ? 1 : 0

  destination_arn = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.destination_arn
  filter_pattern  = ""
  log_group_name  = module.ecs_service_front_end.container_definitions["front-end"].cloudwatch_log_group_name
  name            = "splunk"
  role_arn        = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.role_arn
}
