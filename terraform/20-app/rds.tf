resource "aws_db_instance" "app_rds" {
  allocated_storage     = var.rds_app_db_allocated_storage
  db_name               = "cms"
  db_subnet_group_name  = module.vpc.database_subnet_group
  engine                = var.rds_app_db_engine
  engine_version        = var.rds_app_db_engine_version
  identifier            = "${local.prefix}-db"
  instance_class        = var.rds_app_db_instance_class
  password              = jsondecode(aws_secretsmanager_secret_version.rds_db_creds.secret_string)["password"]
  publicly_accessible   = var.environment_type == "dev"
  skip_final_snapshot   = var.rds_app_db_skip_final_snapshot
  storage_type          = var.rds_app_db_storage_type
  username              = jsondecode(aws_secretsmanager_secret_version.rds_db_creds.secret_string)["username"]
}