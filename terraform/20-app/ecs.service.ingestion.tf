module "ecs_service_ingestion" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.0"

  name        = "${local.prefix}-ingestion"
  cluster_arn = module.ecs.cluster_arn

  cpu                = 512
  memory             = 1024
  subnet_ids         = module.vpc.private_subnets
  enable_autoscaling = false
  desired_count      = 0

  container_definitions = {
    api = {
      cpu                      = 512
      memory                   = 1024
      essential                = true
      readonly_root_filesystem = false
      image                    = "${module.ecr_api.repository_url}:latest"
      port_mappings            = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "APP_MODE"
          value = "INGESTION"
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
        },
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
        }
      ]
    }
  }
}

module "ingestion_tasks_security_group_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  create_sg         = false
  security_group_id = module.ecs_service_ingestion.security_group_id

  egress_with_source_security_group_id = [
    {
      description              = "lb to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_rds_security_group.security_group_id
    }
  ]
}