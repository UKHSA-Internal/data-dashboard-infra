module "ecs_service_cms_admin" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "6.4.0"

  name                   = "${local.prefix}-cms-admin"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  cpu        = local.use_prod_sizing ? 2048 : 512
  memory     = local.use_prod_sizing ? 4096 : 1024
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling       = true
  desired_count            = local.use_prod_sizing ? 3 : 1
  autoscaling_min_capacity = local.use_prod_sizing ? 3 : 1
  autoscaling_max_capacity = local.use_prod_sizing ? 5 : 1

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
    api = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      cpu                                    = local.use_prod_sizing ? 2048 : 512
      memory                                 = local.use_prod_sizing ? 4096 : 1024
      essential                              = true
      readonlyRootFilesystem                = true
      image                                  = module.ecr_back_end_ecs.image_uri
      mountPoints = [
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        },
        {
          sourceVolume  = "tmp"
          containerPath = "/code/metrics/static"
          readOnly      = false
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "APP_MODE"
          value = "CMS_ADMIN"
        },
        {
          name  = "POSTGRES_DB"
          value = module.aurora_db_app.cluster_database_name
        },
        {
          name  = "POSTGRES_HOST"
          value = module.aurora_db_app.cluster_endpoint
        },
        {
          name  = "APIENV"
          value = "PROD"
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

  load_balancer = {
    service = {
      target_group_arn = module.cms_admin_alb.target_groups["${local.prefix}-cms-admin"].arn
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

  task_exec_iam_statements = [
    {
      actions = ["kms:Decrypt"]
      resources = [
        module.kms_secrets_app_engineer.key_arn,
        module.kms_app_rds.key_arn,
        module.kms_secrets_app_operator.key_arn,
      ]
    }
  ]

  security_group_ingress_rules = {
    alb = {
      from_port                    = 80
      to_port                      = 80
      protocol                     = "tcp"
      description                  = "lb to tasks"
      referenced_security_group_id = module.cms_admin_alb.security_group_id
    }
  }
  security_group_egress_rules = {
    db = {
      from_port                    = 5432
      to_port                      = 5432
      protocol                     = "tcp"
      referenced_security_group_id = module.aurora_db_app.security_group_id
    }
    internet = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https to internet"
      cidr_ipv4 = "0.0.0.0/0"
    }
  }
}
