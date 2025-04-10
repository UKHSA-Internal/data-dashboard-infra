module "ecs_service_public_api" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.4"

  name                   = "${local.prefix}-public-api"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  cpu        = local.use_prod_sizing ? 1024 : 512
  memory     = local.use_prod_sizing ? 2048 : 1024
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
    api = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      cpu                                    = local.use_prod_sizing ? 1024 : 512
      memory                                 = local.use_prod_sizing ? 2048 : 1024
      essential                              = true
      readonly_root_filesystem               = false
      image                                  = module.ecr_back_end_ecs.image_uri
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
          value = "PUBLIC_API"
        },
        {
          name  = "FRONTEND_URL"
          value = local.urls.front_end
        },
        {
          name  = "POSTGRES_DB"
          value = local.aurora.app.secondary.db_name
        },
        {
          name  = "POSTGRES_HOST"
          value = local.aurora.app.secondary.address
        },
        {
          name  = "APIENV"
          value = "PROD"
        },
        {
          name  = "AUTH_ENABLED"
          value = local.auth_enabled
        },
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

  load_balancer = {
    service = {
      target_group_arn = module.public_api_alb.target_groups["${local.prefix}-public-api"].arn
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

  task_exec_iam_statements = {
    kms_keys = {
      actions   = ["kms:Decrypt"]
      resources = [
        module.kms_secrets_app_engineer.key_arn,
        module.kms_app_rds.key_arn
      ]
    }
  }

  security_group_rules = {
    # ingress rules
    alb_ingress = {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "lb to tasks"
      source_security_group_id = module.public_api_alb.security_group_id
    }
    # egress rules
    db_egress = {
      type                     = "egress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.aurora_db_app.security_group_id
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
