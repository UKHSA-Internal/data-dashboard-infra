module "ecs_service_private_api" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.9.3"

  name                   = "${local.prefix}-private-api"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  cpu        = local.use_prod_sizing ? 2048 : 512
  memory     = local.use_prod_sizing ? 4096 : 1024
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling       = local.use_auto_scaling
  desired_count            = local.use_auto_scaling ? 3 : 1
  autoscaling_min_capacity = local.use_auto_scaling ? 3 : 1
  autoscaling_max_capacity = local.use_auto_scaling ? 20 : 1

  security_group_ids = [module.app_elasticache_security_group.security_group_id]

  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    api = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      cpu                                    = local.use_prod_sizing ? 2048 : 512
      memory                                 = local.use_prod_sizing ? 4096 : 1024
      essential                              = true
      readonly_root_filesystem               = false
      image                                  = "${module.ecr_api.repository_url}:latest-graviton"
      port_mappings                          = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "APP_MODE"
          value = "PRIVATE_API"
        },
        {
          name  = "POSTGRES_DB"
          value = local.rds.app.private_api_replica.db_name
        },
        {
          name  = "POSTGRES_HOST"
          value = local.rds.app.private_api_replica.address
        },
        {
          name  = "APIENV"
          value = "PROD"
        },
        {
          name  = "REDIS_HOST"
          # The `rediss` prefix is not a typo
          # this is the redis-py native URL notation for an SSL wrapped TCP connection to redis
          value = "rediss://${aws_elasticache_serverless_cache.app_elasticache.endpoint.0.address}:${aws_elasticache_serverless_cache.app_elasticache.endpoint.0.port}"
        }
      ],
      secrets = [
        {
          name      = "POSTGRES_USER"
          valueFrom = "${aws_secretsmanager_secret.rds_db_creds.arn}:username::"
        },
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.rds_db_creds.arn}:password::"
        },
        {
          name      = "SECRET_KEY",
          valueFrom = aws_secretsmanager_secret.backend_cryptographic_signing_key.arn
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.private_api_alb.target_group_arns, 0)
      container_name   = "api"
      container_port   = 80
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

module "private_api_tasks_security_group_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  create_sg         = false
  security_group_id = module.ecs_service_private_api.security_group_id

  ingress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      rule                     = "http-80-tcp"
      source_security_group_id = module.private_api_alb_security_group.security_group_id
    },
    {
      description              = "bastion to tasks"
      rule                     = "http-80-tcp"
      source_security_group_id = module.ecs_service_bastion.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "https to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "lb to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_rds_security_group.security_group_id
    },
    {
      description              = "lb to cache"
      rule                     = "redis-tcp"
      source_security_group_id = module.app_elasticache_security_group.security_group_id
    }
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_service_private_api" {
  count = local.ship_cloud_watch_logs_to_splunk ? 1 : 0

  destination_arn = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.destination_arn
  filter_pattern  = ""
  log_group_name  = module.ecs_service_private_api.container_definitions["api"].cloudwatch_log_group_name
  name            = "splunk"
  role_arn        = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.role_arn
}
