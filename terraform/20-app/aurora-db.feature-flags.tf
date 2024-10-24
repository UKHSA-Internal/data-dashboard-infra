module "aurora_db_feature_flags" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.5.0"

  name              = "${local.prefix}-aurora-db-feature-flags"
  engine            = "aurora-postgresql"
  engine_mode       = "provisioned"
  engine_version    = "15.5"
  storage_encrypted = true

  publicly_accessible = true

  manage_master_user_password = true
  database_name               = "unleash"
  master_username             = "unleash_user"

  monitoring_interval = 60
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

  security_group_rules = {
    feature_flag_tasks_to_db = {
      type                     = "ingress"
      description              = "feature flags tasks to feature flags db"
      protocol                 = "tcp"
      from_port                = 4242
      to_port                  = 5432
      source_security_group_id = module.ecs_service_feature_flags.security_group_id
    }
  }
}
