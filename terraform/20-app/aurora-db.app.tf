module "aurora_db_app" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.6.0"

  name                    = "${local.prefix}-aurora-db-app"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "15.5"
  storage_encrypted       = true
  backup_retention_period = 35
  kms_key_id              = module.kms_app_rds.key_arn

  manage_master_user_password = true
  database_name               = "cms"
  master_username             = "api_user"

  monitoring_interval = 0
  apply_immediately   = true
  skip_final_snapshot = true
  publicly_accessible = local.enable_public_db
  deletion_protection = local.use_prod_sizing

  instance_class = "db.serverless"
  serverlessv2_scaling_configuration = {
    min_capacity = 1
    max_capacity = 10
  }
  instances = local.use_prod_sizing ? { 1 : {}, 2 : {} } : { 1 : {} }

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  security_group_rules = {
    # Ingress rules for connecting services
    private_api_tasks_to_db = {
      type                     = "ingress"
      description              = "private api tasks to main db"
      protocol                 = "tcp"
      source_security_group_id = module.ecs_service_private_api.security_group_id
    },
    public_api_tasks_to_db = {
      type                     = "ingress"
      description              = "public api tasks to main db"
      protocol                 = "tcp"
      source_security_group_id = module.ecs_service_public_api.security_group_id
    },
    cms_admin_tasks_to_db = {
      type                     = "ingress"
      description              = "cms admin tasks to main db"
      protocol                 = "tcp"
      source_security_group_id = module.ecs_service_cms_admin.security_group_id
    },
    utility_worker_tasks_to_db = {
      type                     = "ingress"
      description              = "utility worker tasks to main db"
      protocol                 = "tcp"
      source_security_group_id = module.ecs_service_utility_worker.security_group_id
    },
    ingestion_lambda_to_db = {
      type                     = "ingress"
      description              = "ingestion lambda to main db"
      protocol                 = "tcp"
      source_security_group_id = module.lambda_ingestion_security_group.security_group_id
    },
  }
}

locals {
  aurora = {
    app = {
      primary = {
        db_name = module.aurora_db_app.cluster_database_name
        address = module.aurora_db_app.cluster_endpoint
      }
      public_api_replica = {
        db_name = module.aurora_db_app.cluster_database_name
        address = module.aurora_db_app.cluster_reader_endpoint
      }
      private_api_replica = {
        db_name = module.aurora_db_app.cluster_database_name
        address = module.aurora_db_app.cluster_reader_endpoint
      }
    }
  }
}
