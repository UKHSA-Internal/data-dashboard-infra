# Postgres database RDS
data "aws_secretsmanager_secret" "secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:574290571051:secret:rds/postgres-e9vo14"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}

variable "subnet_id_1" {default = "subnet-0e46d470a44e33e79"}
variable "subnet_id_2" {default = "subnet-078da0d9d54aeed64"}
variable "subnet_id_3" {default = "subnet-0b9f20fcc12e0d218"}

data "aws_subnet" "subnet_1" {
  id = var.subnet_id_1
}

data "aws_subnet" "subnet_2" {
  id = var.subnet_id_2
}

data "aws_subnet" "subnet_3" {
  id = var.subnet_id_3
}


data "aws_subnets" "app_subnets"{
  filter{
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_db_subnet_group" "default" {
  name        = "main"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [var.subnet_id_1,var.subnet_id_2,var.subnet_id_3]
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
  db_subnet_group_name      = "${aws_db_subnet_group.default.id}"
  skip_final_snapshot       = true
}

