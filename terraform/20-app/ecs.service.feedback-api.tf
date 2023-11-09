module "ecs_service_feedback_api" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.6.0"

  name        = "${local.prefix}-feedback-api"
  cluster_arn = module.ecs.cluster_arn

  cpu                = local.use_prod_sizing ? 2048 : 512
  memory             = local.use_prod_sizing ? 4096 : 1024
  subnet_ids         = module.vpc.private_subnets
  
  enable_autoscaling       = local.use_auto_scaling
  desired_count            = local.use_auto_scaling ? 3 : 1
  autoscaling_min_capacity = local.use_auto_scaling ? 3 : 1
  autoscaling_max_capacity = local.use_auto_scaling ? 20 : 1

  container_definitions = {
    api = {
      cpu                      = local.use_prod_sizing ? 2048 : 512
      memory                   = local.use_prod_sizing ? 4096 : 1024
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
