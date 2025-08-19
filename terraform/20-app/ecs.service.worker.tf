module "ecs_service_worker" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "6.2.2"

  name                   = "${local.prefix}-worker"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  cpu        = 512
  memory     = 1024
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling = false
  desired_count      = 0

  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = {
    api = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      cpu                                    = 512
      memory                                 = 1024
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
          value = "UTILITY_WORKER"
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

  task_exec_iam_statements = {
    kms_keys = {
      actions   = ["kms:Decrypt"]
      resources = [
        module.kms_secrets_app_engineer.key_arn,
        module.kms_app_rds.key_arn,
      ]
    }
  }

  security_group_rules = {
    # egress rules
    internet_egress = {
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https to internet"
      cidr_blocks = ["0.0.0.0/0"]
    }
    db_egress = {
      type                     = "egress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.aurora_db_app.security_group_id
    }
  }
}
