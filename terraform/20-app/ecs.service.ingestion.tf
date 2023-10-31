module "ecs_service_ingestion" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.4.0"

  name        = "${local.prefix}-ingestion"
  cluster_arn = module.ecs.cluster_arn

  cpu                = 16384
  memory             = 32768
  subnet_ids         = module.vpc.private_subnets
  enable_autoscaling = false
  desired_count      = 0

  tasks_iam_role_statements = [
    # Gives permission to list information at the bucket-level
    {
      actions = [
        "s3:ListBucket"
      ]
      effect    = "Allow"
      resources = [module.s3_ingest.s3_bucket_arn]
    },
    # Gives permission to list all files within the `in/` folder
    {
      actions = [
        "s3:ListObjects"
      ]
      effect    = "Allow"
      resources = ["${module.s3_ingest.s3_bucket_arn}/in"]
    },
    # Gives permission to download & delete files from the `in/` folder
    # Note that there is strictly no move-type operation hence the need to combine get and delete
    {
      actions = [
        "s3:GetObject",
        "s3:DeleteObject"
      ]
      effect    = "Allow"
      resources = ["${module.s3_ingest.s3_bucket_arn}/in/*"]
    },
    # Gives permission to add files to the `processed/` folder
    {
      actions = [
        "s3:PutObject"
      ]
      effect    = "Allow"
      resources = ["${module.s3_ingest.s3_bucket_arn}/processed/*"]
    },
    # Gives permission to add files to the `failed/` folder
    {
      actions = [
        "s3:PutObject"
      ]
      effect    = "Allow"
      resources = ["${module.s3_ingest.s3_bucket_arn}/failed/*"]
    }
  ]

  container_definitions = {
    api = {
      cpu                      = 16384
      memory                   = 32768
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
          name  = "INGESTION_BUCKET_NAME"
          value = module.s3_ingest.s3_bucket_id
        },
        {
          name  = "POSTGRES_DB"
          value = local.rds.app.primary.db_name
        },
        {
          name  = "POSTGRES_HOST"
          value = local.rds.app.primary.address
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
