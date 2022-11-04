# Postgres database RDS
data "aws_secretsmanager_secret" "secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:574290571051:secret:rds/postgres-e9vo14"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}

# Networking

data "aws_subnets" "app_subnets"{
  filter{
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_db_instance" "app_rds" {
  identifier                = "${var.project_name}-rds"
  allocated_storage         = var.rds_allocated_storage
  engine                    = var.rds_engine
  engine_version            = var.rds_engine_version
  instance_class            = var.rds_instance_class
  username                  = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["rds_username"]
  password                  = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["rds_password"]
  storage_type              = var.rds_storage_type
  db_subnet_group_name      = "vpc-id"
  skip_final_snapshot       = true
}

