module "ecs_service_feature_flags" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.4"

  name                   = "${local.prefix}-feature-flags"
  cluster_arn            = module.ecs.cluster_arn
  enable_execute_command = true

  create_iam_role = true

  cpu        = 256
  memory     = 512
  subnet_ids = module.vpc.private_subnets

  enable_autoscaling       = true
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 1

  runtime_platform = {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
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
      target_group_arn = module.feature_flags_alb.target_groups["${local.prefix}-feature-flags-tg"].arn
      container_name   = "api"
      container_port   = 4242
    }
  }

  security_group_rules = {
    # ingress rules
    alb_ingress = {
      type                     = "ingress"
      from_port                = 4242
      to_port                  = 4242
      protocol                 = "tcp"
      description              = "lb to tasks"
      source_security_group_id = module.feature_flags_alb.security_group_id
    }
    # egress rules
    db_egress = {
      type                     = "egress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.aurora_db_feature_flags.security_group_id
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
