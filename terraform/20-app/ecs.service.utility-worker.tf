module "ecs_service_utility_worker" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.0"

  name        = "${local.prefix}-utility-worker"
  cluster_arn = module.ecs.cluster_arn

  cpu        = 16384
  memory     = 32768
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling = false
  desired_count      = 0

  security_group_ids = [module.app_elasticache_security_group.security_group_id]

  container_definitions = {
    api = {
      cpu                      = 16384
      memory                   = 32768
      essential                = true
      readonly_root_filesystem = false
      image                    = "${module.ecr_api.repository_url}:latest"
      port_mappings            = [
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
}

module "utility_worker_tasks_security_group_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  create_sg         = false
  security_group_id = module.ecs_service_utility_worker.security_group_id

  ingress_with_source_security_group_id = [
    {
      description              = "utility worker tasks to tasks"
      rule                     = "http-80-tcp"
      source_security_group_id = module.private_api_alb_security_group.security_group_id
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
      description              = "utility worker tasks to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_rds_security_group.security_group_id
    },
    {
      description              = "utility worker tasks to cache"
      rule                     = "redis-tcp"
      source_security_group_id = module.app_elasticache_security_group.security_group_id
    }
  ]
}