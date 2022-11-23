

data "aws_subnet" "subnet_1" {
  id = var.subnet_id_1
}

data "aws_subnet" "subnet_2" {
  id = var.subnet_id_2
}

data "aws_subnet" "subnet_3" {
  id = var.subnet_id_3
}

data "aws_subnet" "subnet_4" {
  id = var.subnet_id_4
}

data "aws_subnet" "subnet_4" {
  id = var.subnet_id_5
}

data "aws_subnet" "subnet_4" {
  id = var.subnet_id_6
}

data "aws_subnet" "subnet_4" {
  id = var.subnet_id_7
}

data "aws_subnets" "app_subnets"{
  filter{
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_db_subnet_group" "default" {
  name        = "main1"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [var.subnet_id_1,var.subnet_id_2,var.subnet_id_3,var.subnet_id_4,var.subnet_id_5,var.subnet_id_6,var.subnet_id_7]
}

