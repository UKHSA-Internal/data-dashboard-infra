module "ecs_service_feature_flags" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.10.0"

  name                   = "${local.prefix}-feature-flags"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  create_iam_role = true

  cpu              = 256
  memory           = 512
  runtime_platform = {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling       = true
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 1

  autoscaling_scheduled_actions = local.use_prod_sizing ? {} : local.scheduled_scaling_policies_for_non_essential_envs

  container_definitions = {
    api = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      cpu                                    = 256
      memory                                 = 512
      essential                              = true
      readonly_root_filesystem               = false
      image                                  = "unleashorg/unleash-server:5.10.1"
      port_mappings                          = [
        {
          containerPort = 4242
          hostPort      = 4242
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "UNLEASH_URL"
          value = local.urls.feature_flags
        },
        {
          name  = "UNLEASH_PROXY_CLIENT_KEYS"
          value = "Authorization"
        },
        {
          name  = "DATABASE_HOST"
          value = module.aurora_db_feature_flags.cluster_endpoint
        },
        {
          name  = "DATABASE_NAME"
          value = module.aurora_db_feature_flags.cluster_database_name
        },
      ],
      secrets = [
        {
          name      = "INIT_CLIENT_API_TOKENS"
          valueFrom = "${aws_secretsmanager_secret.feature_flags_api_keys.arn}:client_api_key::"
        },
        {
          name      = "UNLEASH_DEFAULT_ADMIN_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.feature_flags_admin_user_credentials.arn}:username::"
        },
        {
          name      = "UNLEASH_DEFAULT_ADMIN_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.feature_flags_admin_user_credentials.arn}:password::"
        },
        {
          name      = "DATABASE_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.aurora_db_feature_flags_credentials.arn}:username::"
        },
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.aurora_db_feature_flags_credentials.arn}:password::"
        },
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.feature_flags_alb.target_group_arns, 0)
      container_name   = "api"
      container_port   = 4242
    }
  }
}


module "feature_flags_tasks_security_group_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  create_sg         = false
  security_group_id = module.ecs_service_feature_flags.security_group_id

  ingress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      from_port                = 4242
      to_port                  = 4242
      protocol                 = "tcp"
      source_security_group_id = module.feature_flags_alb_security_group.security_group_id
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
      description              = "lb to feature flags db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.aurora_db_feature_flags.security_group_id
    }
  ]
}
