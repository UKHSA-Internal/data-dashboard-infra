module "ecs_service_front_end" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.0.0"

  name        = "${local.prefix}-front-end"
  cluster_arn = module.ecs.cluster_arn

  cpu              = 256
  memory           = 512
  assign_public_ip = true
  subnet_ids       = module.vpc.public_subnets

  container_definitions = {
    front-end = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      port_mappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "API_KEY"
          value = aws_secretsmanager_secret_version.cms_api_key.secret_string
        },
        {
          name  = "API_URL"
          value = "http://${module.api_alb.lb_dns_name}"
        },
        {
          name  = "NEXT_REVALIDATE_TIME"
          value = "false"
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
  source = "terraform-aws-modules/security-group/aws"

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
