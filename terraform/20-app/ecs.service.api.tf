module "ecs_service_api" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.0.1"

  name        = "${local.prefix}-api"
  cluster_arn = module.ecs.cluster_arn

  cpu              = 256
  memory           = 512
  assign_public_ip = true
  subnet_ids       = module.vpc.public_subnets

  container_definitions = {
    api = {
      cpu                      = 256
      memory                   = 512
      essential                = true
      readonly_root_filesystem = false
      image                    = "${aws_ecr_repository.api.repository_url}:latest"
      port_mappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
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
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.api_alb.target_group_arns, 0)
      container_name   = "api"
      container_port   = 80
    }
  }
}

module "api_tasks_security_group_rules" {
  source = "terraform-aws-modules/security-group/aws"

  create_sg         = false
  security_group_id = module.ecs_service_api.security_group_id

  ingress_with_source_security_group_id = [
    {
      description              = "lb to tasks"
      rule                     = "http-80-tcp"
      source_security_group_id = module.api_alb_security_group.security_group_id
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
      description              = "lb to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_rds_security_group.security_group_id
    }
  ]
}
