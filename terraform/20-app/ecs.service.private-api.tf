module "ecs_service_private_api" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.0"

  name        = "${local.prefix}-private-api"
  cluster_arn = module.ecs.cluster_arn

  cpu                = 512
  memory             = 1024
  assign_public_ip   = true
  subnet_ids         = module.vpc.public_subnets
  enable_autoscaling = false
  desired_count      = 1

  container_definitions = {
    api = {
      cpu                      = 512
      memory                   = 1024
      essential                = true
      readonly_root_filesystem = false
      image                    = "${module.ecr_api.repository_url}:latest"
      port_mappings = [
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
          value = aws_db_instance.app_rds.db_name
        },
        {
          name  = "POSTGRES_HOST"
          value = aws_db_instance.app_rds.address
        },
        {
          name  = "APIENV"
          value = "PROD"
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
        },
        {
          name      = "EMAIL_HOST_USER",
          valueFrom ="${aws_secretsmanager_secret.private_api_email_credentials.arn}:email_host_user::"
        },
        {
          name      = "EMAIL_HOST_PASSWORD",
          valueFrom ="${aws_secretsmanager_secret.private_api_email_credentials.arn}:email_host_password::"
        },
        {
          name      = "FEEDBACK_EMAIL_RECIPIENT_ADDRESS",
          valueFrom ="${aws_secretsmanager_secret.private_api_email_credentials.arn}:feedback_email_recipient_address::"
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
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "https to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 587
      to_port     = 587
      protocol    = "tcp"
      description = "Allow SMTP traffic from egress"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_source_security_group_id = [
    {
      description              = "lb to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_rds_security_group.security_group_id
    }
  ]
}
