module "ecs_service_feedback_api" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.10.0"

  name                   = "${local.prefix}-feedback-api"
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

  container_definitions = {
    api = {
      cloudwatch_log_group_retention_in_days = local.default_log_retention_in_days
      cpu                                    = local.use_prod_sizing ? 1024 : 512
      memory                                 = local.use_prod_sizing ? 2048 : 1024
      essential                              = true
      readonly_root_filesystem               = false
      image                                  = "${module.ecr_api.repository_url}:latest"
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
          value = "FEEDBACK_API"
        },
        {
          name  = "APIENV"
          value = "STANDALONE"
        },
      ],
      secrets = [
        {
          name      = "SECRET_KEY",
          valueFrom = aws_secretsmanager_secret.backend_cryptographic_signing_key.arn
        },
        {
          name      = "EMAIL_HOST_USER",
          valueFrom = "${aws_secretsmanager_secret.private_api_email_credentials.arn}:email_host_user::"
        },
        {
          name      = "EMAIL_HOST_PASSWORD",
          valueFrom = "${aws_secretsmanager_secret.private_api_email_credentials.arn}:email_host_password::"
        },
        {
          name      = "FEEDBACK_EMAIL_RECIPIENT_ADDRESS",
          valueFrom = "${aws_secretsmanager_secret.private_api_email_credentials.arn}:feedback_email_recipient_address::"
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.feedback_api_alb.target_group_arns, 0)
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
}

module "feedback_api_tasks_security_group_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  create_sg         = false
  security_group_id = module.ecs_service_feedback_api.security_group_id

  ingress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      rule                     = "http-80-tcp"
      source_security_group_id = module.feedback_api_alb_security_group.security_group_id
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
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_service_feedback_api" {
  count = local.ship_cloud_watch_logs_to_splunk ? 1 : 0

  destination_arn = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.destination_arn
  filter_pattern  = ""
  log_group_name  = module.ecs_service_feedback_api.container_definitions["api"].cloudwatch_log_group_name
  name            = "splunk"
  role_arn        = local.account_layer.kinesis.cloud_watch_logs_to_splunk.eu_west_2.role_arn
}
