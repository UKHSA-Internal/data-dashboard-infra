moved {
  from = aws_db_instance.app_rds
  to   = aws_db_instance.app_rds_primary
}

locals {
  engine_version = "15.5"
}

resource "aws_db_instance" "app_rds_primary" {
  allocated_storage           = local.use_prod_sizing ? 50 : 20
  allow_major_version_upgrade = true
  apply_immediately           = true
  backup_retention_period     = 35
  db_name                     = "cms"
  db_subnet_group_name        = module.vpc.database_subnet_group
  engine                      = "postgres"
  engine_version              = local.engine_version
  identifier                  = "${local.prefix}-db"
  instance_class              = local.use_prod_sizing ? "db.t3.medium" : "db.t3.small"
  kms_key_id                  = module.kms_app_rds.key_arn
  multi_az                    = local.use_prod_sizing ? true : false
  password                    = jsondecode(aws_secretsmanager_secret_version.rds_db_creds.secret_string)["password"]
  publicly_accessible         = local.enable_public_db
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp3"
  username                    = jsondecode(aws_secretsmanager_secret_version.rds_db_creds.secret_string)["username"]
  vpc_security_group_ids      = [module.app_rds_security_group.security_group_id]
}

resource "aws_db_instance" "app_rds_private_api_read_replica" {
  allow_major_version_upgrade = true
  apply_immediately           = true
  count                       = local.use_prod_sizing ? 1 : 0
  identifier                  = "${local.prefix}-db-private-api-read-replica"
  instance_class              = "db.t3.medium"
  kms_key_id                  = module.kms_app_rds.key_arn
  multi_az                    = true
  replicate_source_db         = aws_db_instance.app_rds_primary.identifier
  engine_version              = local.engine_version
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp3"
  vpc_security_group_ids      = [module.app_rds_security_group.security_group_id]
}

resource "aws_db_instance" "app_rds_public_api_read_replica" {
  allow_major_version_upgrade = true
  apply_immediately           = true
  count                       = local.use_prod_sizing ? 1 : 0
  identifier                  = "${local.prefix}-db-public-api-read-replica"
  instance_class              = "db.t3.medium"
  kms_key_id                  = module.kms_app_rds.key_arn
  multi_az                    = true
  replicate_source_db         = aws_db_instance.app_rds_primary.identifier
  engine_version              = local.engine_version
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp3"
  vpc_security_group_ids      = [module.app_rds_security_group.security_group_id]
}

locals {
  rds = {
    app = {
      primary = {
        db_name = aws_db_instance.app_rds_primary.db_name
        address = aws_db_instance.app_rds_primary.address
      }
      public_api_replica = {
        db_name = local.use_prod_sizing ? aws_db_instance.app_rds_public_api_read_replica[0].db_name : aws_db_instance.app_rds_primary.db_name
        address = local.use_prod_sizing ? aws_db_instance.app_rds_public_api_read_replica[0].address : aws_db_instance.app_rds_primary.address
      }
      private_api_replica = {
        db_name = local.use_prod_sizing ? aws_db_instance.app_rds_private_api_read_replica[0].db_name : aws_db_instance.app_rds_primary.db_name
        address = local.use_prod_sizing ? aws_db_instance.app_rds_private_api_read_replica[0].address : aws_db_instance.app_rds_primary.address
      }
    }
  }
}


module "app_rds_security_group_rules" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  count             = local.is_dev ? 1 : 0
  create_sg         = false
  security_group_id = module.app_rds_security_group.security_group_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "engineers access to app db"
      cidr_blocks = join(",", local.ip_allow_list.engineers)
    }
  ]
}

module "app_rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "${local.prefix}-app-db"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "private api tasks to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.ecs_service_private_api.security_group_id
    },
    {
      description              = "public api tasks to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.ecs_service_public_api.security_group_id
    },
    {
      description              = "cms admin tasks to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.ecs_service_cms_admin.security_group_id
    },
    {
      description              = "utility worker tasks to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.ecs_service_utility_worker.security_group_id
    },
    {
      description              = "rds proxy to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.rds_proxy_security_group.security_group_id
    },
  ]
}
