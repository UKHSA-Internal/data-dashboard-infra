module "rds_proxy" {
  source = "terraform-aws-modules/rds-proxy/aws"

  name                   = "${local.prefix}-rds-proxy"
  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.app_rds_security_group.security_group_id]

  endpoints = {
    read_write = {
      name                   = "read-write-endpoint"
      vpc_subnet_ids         = module.vpc.private_subnets
      vpc_security_group_ids = [module.app_rds_security_group.security_group_id]
    }
  }

  auth = {
    api_user = {
      secret_arn = aws_secretsmanager_secret.rds_db_creds.arn
    }
  }

  engine_family          = "POSTGRESQL"
  debug_logging          = true
  target_db_instance     = true
  db_instance_identifier = aws_db_instance.app_rds_primary.identifier
}
