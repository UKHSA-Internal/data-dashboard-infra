resource "aws_db_instance" "app_rds" {
  allocated_storage           = var.rds_app_db_allocated_storage
  allow_major_version_upgrade = true
  apply_immediately           = true
  backup_retention_period     = 35
  db_name                     = "cms"
  db_subnet_group_name        = module.vpc.database_subnet_group
  engine                      = var.rds_app_db_engine
  engine_version              = var.rds_app_db_engine_version
  identifier                  = "${local.prefix}-db"
  instance_class              = var.rds_app_db_instance_class
  kms_key_id                  = module.kms_app_rds.key_arn
  password                    = jsondecode(aws_secretsmanager_secret_version.rds_db_creds.secret_string)["password"]
  publicly_accessible         = local.enable_public_db
  skip_final_snapshot         = var.rds_app_db_skip_final_snapshot
  storage_encrypted           = true
  storage_type                = var.rds_app_db_storage_type
  username                    = jsondecode(aws_secretsmanager_secret_version.rds_db_creds.secret_string)["username"]
  vpc_security_group_ids      = [module.app_rds_security_group.security_group_id]
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
    }
  ]
}
