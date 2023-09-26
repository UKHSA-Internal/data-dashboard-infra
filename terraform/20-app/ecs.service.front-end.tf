module "ecs_service_front_end" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.0"

  name        = "${local.prefix}-front-end"
  cluster_arn = module.ecs.cluster_arn

  cpu                = local.use_prod_sizing ? 2048 : 512
  memory             = local.use_prod_sizing ? 4096 : 1024
  subnet_ids         = module.vpc.private_subnets

  enable_autoscaling       = local.use_auto_scaling
  desired_count            = local.use_auto_scaling ? 3 : 1
  autoscaling_min_capacity = local.use_auto_scaling ? 3 : 1
  autoscaling_max_capacity = local.use_auto_scaling ? 20 : 1

  container_definitions = {
    front-end = {
      cpu                      = local.use_prod_sizing ? 2048 : 512
      memory                   = local.use_prod_sizing ? 4096 : 1024
      essential                = true
      readonly_root_filesystem = false
      image                    = "${module.ecr_front_end.repository_url}:latest"
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
          name  = "FEEDBACK_API_URL"
          value = local.urls.feedback_api
        },
        # Variables intended for the browser require the NEXT_PUBLIC_ prefix
        # https://nextjs.org/docs/pages/building-your-application/configuring/environment-variables#bundling-environment-variables-for-the-browser
        {
          name  = "NEXT_PUBLIC_PUBLIC_API_URL"
          value = local.urls.public_api
        },
        {
          name  = "NEXT_REVALIDATE_TIME"
          value = "360"
        }
      ]
      secrets = [
        {
          name      = "API_KEY"
          valueFrom = aws_secretsmanager_secret.private_api_key.arn
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.front_end_alb.target_group_arns, 0)
      container_name   = "front-end"
      container_port   = 3000
    }
  }
}

module "front_end_tasks_security_group_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  create_sg         = false
  security_group_id = module.ecs_service_front_end.security_group_id

  ingress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "TCP"
      source_security_group_id = module.front_end_alb_security_group.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "https to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "to api"
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
