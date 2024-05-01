module "aurora_db_main" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name              = "${local.prefix}-aurora-db-main"
  engine            = "aurora-postgresql"
  engine_mode       = "provisioned"
  engine_version    = "15.5"
  storage_encrypted = true
  kms_key_id        = module.kms_app_rds.key_arn

  is_primary_cluster            = false
  replication_source_identifier = aws_db_instance.app_rds_primary.arn
  manage_master_user_password   = false

  monitoring_interval = 0
  apply_immediately   = true
  skip_final_snapshot = true

  instance_class = "db.serverless"
  serverlessv2_scaling_configuration = {
    min_capacity = 1
    max_capacity = 10
  }
  instances = {
    1 = {}
  }

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name
}
