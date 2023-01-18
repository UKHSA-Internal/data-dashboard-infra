# Postgres database RDS
data "aws_secretsmanager_secret" "secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:039901296652:secret:rds_credentials-vC77QM"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "main"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [aws_subnet.subnet_1.id,aws_subnet.subnet_2.id,aws_subnet.subnet_3.id]
}

resource "aws_db_instance" "app_rds" {
  identifier                = "${var.project_name}-rds"
  db_name                   = var.rds_db_name
  allocated_storage         = var.rds_allocated_storage
  engine                    = var.rds_engine
  engine_version            = var.rds_engine_version
  instance_class            = var.rds_instance_class
  username                  = "wp_user"
  password                  = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["rds_password"]
  storage_type              = var.rds_storage_type
  db_subnet_group_name      = "${aws_db_subnet_group.rds_subnet_group.id}"
  skip_final_snapshot       = true
}

