module "ecs_service_front_end" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.0"

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
      image                                  = module.ecr_front_end_ecs.image_uri
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
        }
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

  task_exec_iam_statements = {
    kms_keys = {
      actions   = ["kms:Decrypt"]
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
    private_api_egress = {
      type        = "egress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
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
