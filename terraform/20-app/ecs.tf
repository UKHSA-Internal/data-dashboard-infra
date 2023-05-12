locals {
    ecs = {
        services = {
            front_end = "${local.prefix}-front-end"
            api       = "${local.prefix}-api"
        }
    }
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${local.prefix}-cluster"

  services = {
    (local.ecs.services.front_end) = {
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
                name = "NEXT_PUBLIC_API_URL"
                value = module.api_alb.lb_dns_name
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

    (local.ecs.services.api) = {
      cpu              = 256
      memory           = 512
      assign_public_ip = true
      subnet_ids       = module.vpc.public_subnets

      container_definitions = {
        api = {
          cpu       = 256
          memory    = 512
          essential = true
          image     = "${aws_ecr_repository.api.repository_url}:latest"
          port_mappings = [
                {
                    containerPort = 80
                    hostPort      = 80
                    protocol      = "tcp"
                }
           ]
           environment = [
             {
                name = "POSTGRES_USER"
                value = jsondecode(aws_secretsmanager_secret_version.rds_db_creds.secret_string)["username"]
             }, 
             {
                name = "POSTGRES_PASSWORD"
                value = jsondecode(aws_secretsmanager_secret_version.rds_db_creds.secret_string)["password"]
             }, 
             {
                name = "POSTGRES_DB"
                value = aws_db_instance.app_rds.db_name
             }, 
             {
                name = "POSTGRES_HOST"
                value = aws_db_instance.app_rds.address
             }, 
             {
                name = "APIENV"
                value = "PROD"
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
  }
}

module "front_end_tasks_security_group_rules" {
    source = "terraform-aws-modules/security-group/aws"

    create_sg         = false
    security_group_id = module.ecs.services[local.ecs.services.front_end].security_group_id 

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
            description     = "https to internet"
            rule            = "https-443-tcp"
            cidr_blocks     = "0.0.0.0/0"
        }
    ]

    egress_with_source_security_group_id = [
        {
            description              = "to api"
            rule                     = "http-80-tcp"
            source_security_group_id = module.api_alb_security_group.security_group_id
        }
    ]
}

module "api_tasks_security_group_rules" {
    source = "terraform-aws-modules/security-group/aws"

    create_sg         = false
    security_group_id = module.ecs.services[local.ecs.services.api].security_group_id 

    ingress_with_source_security_group_id = [
        {
            description              = "lb to tasks"
            rule                     = "http-80-tcp"
            source_security_group_id = module.api_alb_security_group.security_group_id
        }
    ]

    egress_with_cidr_blocks = [
        {
            description     = "https to internet"
            rule            = "https-443-tcp"
            cidr_blocks     = "0.0.0.0/0"
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