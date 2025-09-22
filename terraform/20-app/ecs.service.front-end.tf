module "ecs_service_front_end" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "6.4.0"

  name                   = "${local.prefix}-front-end"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  cpu        = local.use_prod_sizing ? 2048 : 512
  memory     = local.use_prod_sizing ? 4096 : 1024
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling       = true
  desired_count            = local.use_prod_sizing ? 6 : 1
  autoscaling_min_capacity = local.use_prod_sizing ? 6 : 1
  autoscaling_max_capacity = local.use_prod_sizing ? 20 : 1

  autoscaling_scheduled_actions = local.is_scaled_down_overnight ? local.non_essential_envs_scheduled_policy : {}

  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  ephemeral_storage = {
    size_in_gib = 21
  }
  volume = {
    tmp = {}
  }

  container_definitions = {
    front-end = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      cpu                                    = local.use_prod_sizing ? 2048 : 512
      memory                                 = local.use_prod_sizing ? 4096 : 1024
      essential                              = true
      readonly_root_filesystem               = true
      image                                  = module.ecr_front_end_ecs.image_uri
      mount_points = [
        {
          sourceVolume  = "tmp"
          containerPath = "/app/.next/cache"
          readOnly      = false
        }
      ]
      port_mappings = [
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
          name  = "BASE_URL"
          value = local.urls.front_end
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
        },
        {
          name  = "RUM_IDENTITY_POOL_ID"
          value = module.cloudwatch_rum_front_end.rum_cognito_pool_id
        },
        {
          name  = "RUM_APPLICATION_ID"
          value = module.cloudwatch_rum_front_end.rum_application_id
        },
        {
          name  = "REDIS_HOST"
          value = "rediss://${aws_elasticache_serverless_cache.front_end_elasticache.endpoint.0.address}:${aws_elasticache_serverless_cache.front_end_elasticache.endpoint.0.port}"
        },
        {
          name  = "AUTH_ENABLED",
          value = local.auth_enabled
        },
        {
          name  = "CACHING_V2_ENABLED",
          value = local.caching_v2_enabled
        },
        {
          name  = "AUTH_DOMAIN"
          value = module.cognito.cognito_oauth_url
        },
        {
          name  = "NEXTAUTH_URL"
          value = local.urls.front_end
        },
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
          name      = "FEATURE_FLAGS_AUTH_KEY",
          valueFrom = "${aws_secretsmanager_secret.feature_flags_api_keys.arn}:x_auth::"
        },
        {
          name      = "ESRI_API_KEY"
          valueFrom = "${aws_secretsmanager_secret.esri_api_key.arn}:esri_api_key::"
        },
        {
          name      = "ESRI_CLIENT_URL"
          valueFrom = "${aws_secretsmanager_secret.esri_maps_service_credentials.arn}:client_url::"
        },
        {
          name      = "ESRI_CLIENT_ID"
          valueFrom = "${aws_secretsmanager_secret.esri_maps_service_credentials.arn}:client_id::"
        },
        {
          name      = "ESRI_CLIENT_SECRET"
          valueFrom = "${aws_secretsmanager_secret.esri_maps_service_credentials.arn}:client_secret::"
        },
        {
          name      = "AUTH_SECRET"
          valueFrom = "${aws_secretsmanager_secret.auth_secret.arn}:auth_secret::"
        },
        {
          name      = "AUTH_CLIENT_URL"
          valueFrom = "${aws_secretsmanager_secret.cognito_service_credentials.arn}:client_url::"
        },
        {
          name      = "AUTH_CLIENT_ID"
          valueFrom = "${aws_secretsmanager_secret.cognito_service_credentials.arn}:client_id::"
        },
        {
          name      = "AUTH_CLIENT_SECRET"
          valueFrom = "${aws_secretsmanager_secret.cognito_service_credentials.arn}:client_secret::"
        },
        {
          name      = "REVALIDATE_SECRET"
          valueFrom = "${aws_secretsmanager_secret.revalidate_secret.arn}:revalidate_secret::"
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.front_end_alb.target_groups["${local.prefix}-front-end"].arn
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

  task_exec_iam_statements = {
    kms_keys = {
      actions = ["kms:Decrypt"]
      resources = [
        module.kms_secrets_app_engineer.key_arn,
        module.kms_secrets_app_operator.key_arn,
      ]
    }
  }

  security_group_rules = {
    # ingress rules
    alb_ingress = {
      type                     = "ingress"
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "lb to tasks"
      source_security_group_id = module.front_end_alb.security_group_id
    }
    # egress rules
    internet_egress = {
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https to internet"
      cidr_blocks = ["0.0.0.0/0"]
    },
    cache_egress = {
      type                     = "egress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      source_security_group_id = module.front_end_elasticache_security_group.security_group_id
    }
  }
}
