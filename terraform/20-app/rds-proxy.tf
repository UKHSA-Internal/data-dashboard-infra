module "rds_proxy" {
  source = "terraform-aws-modules/rds-proxy/aws"

  name                   = "${local.prefix}-rds-proxy"
  vpc_subnet_ids         = module.vpc.database_subnets
  vpc_security_group_ids = [module.rds_proxy_security_group.security_group_id]

  auth = {
    api_user = {
      iam_auth   = "DISABLED"
      secret_arn = local.main_db_password_secret_arn
    }
  }

  engine_family          = "POSTGRESQL"
  debug_logging          = true
  target_db_instance     = true
  db_instance_identifier = aws_db_instance.app_rds_primary.identifier
}


module "rds_proxy_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "${local.prefix}-app-db"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "ingestion lambda to proxy"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.lambda_ingestion_security_group.security_group_id
    },
  ]

  egress_with_source_security_group_id = [
    {
      description              = "rds proxy to db"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_rds_security_group.security_group_id
    },
  ]
}
