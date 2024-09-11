module "ecs_service_utility_worker" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.4"

  name                   = "${local.prefix}-utility-worker"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  cpu        = 16384
  memory     = 32768
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling = false
  desired_count      = 0

  security_group_ids = [module.app_elasticache_security_group.security_group_id]

  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    api = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      cpu                                    = 16384
      memory                                 = 32768
      essential                              = true
      readonly_root_filesystem               = false
      image                                  = data.aws_ecr_image.api.image_uri
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
          value = "UTILITY_WORKER"
        },
        {
          name  = "POSTGRES_DB"
          value = local.aurora.app.private_api_replica.db_name
        },
        {
          name  = "POSTGRES_HOST"
          value = local.aurora.app.private_api_replica.address
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
          valueFrom = "${local.main_db_aurora_password_secret_arn}:username::"
        },
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${local.main_db_aurora_password_secret_arn}:password::"
        },
        {
          name      = "SECRET_KEY",
          valueFrom = aws_secretsmanager_secret.backend_cryptographic_signing_key.arn
        }
      ]
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
  security_group_rules = {
    # ingress rules
    alb_ingress = {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.private_api_alb.security_group_id
    }
    # egress rules
    db_egress = {
      type                     = "egress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.aurora_db_app.security_group_id
    }
    cache_egress = {
      type                     = "egress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      source_security_group_id = module.app_elasticache_security_group.security_group_id
    }
    internet_egress = {
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https to internet"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
