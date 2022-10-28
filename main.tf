# Config
variable "aws_region" { default = "eu-west-2" }
variable "aws_profile" {default = "default"}
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}


# Variables
variable "vpc_id" {default = "vpc-039ef980889e0e179"}
variable "project_name" {default = "wl-test"}
variable "launch_type" { default = "FARGATE" }

variable "rds_allocated_storage" {default = "10"}
variable "rds_engine" {default = "postgres"}
variable "rds_engine_version" {default = "13.7"}
variable "rds_instance_class" {default = "db.t3.micro"}
variable "rds_storage_type" { default = "standard" }

variable "database_name" {default = "database-2"}
variable "database_user" {default = "fargate"}
variable "database_password" {default = "Testing123"}

variable "docker_image_name" {default = "martinzugnoni/sampleapp"}
variable "docker_image_revision" {default = "0.0.1"}


# Networking
data "aws_vpc" "app_vpc" {
  id = var.vpc_id
}
data "aws_subnets" "app_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.app_vpc.id]
  }
}
data "aws_security_groups" "app_sg" {
  filter {
    name   = "group-name"
    values = ["default"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.app_vpc.id]
  }
}


# Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.project_name}-cluster"
}


# Service
resource "aws_ecs_service" "app_service" {
  name        = "${var.project_name}-service"
  cluster     = aws_ecs_cluster.app_cluster.arn
  launch_type = var.launch_type

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0
  desired_count                      = 2
  task_definition                    = aws_ecs_task_definition.django_app.arn

  network_configuration {
    assign_public_ip = true
    security_groups  = data.aws_security_groups.app_sg.ids
    subnets          = data.aws_subnets.app_subnet.ids
  }


}


# Task definition
data "template_file" "django_app" {
  template = file("./task-definition.json")
  vars = {
    app_name       = var.project_name
    app_image      = "${var.docker_image_name}:${var.docker_image_revision}"
    app_port       = 8000
    app_db_address = aws_db_instance.app_rds.address
    app_db_port    = aws_db_instance.app_rds.port
    fargate_cpu    = "256"
    fargate_memory = "512"
    aws_region     = var.aws_region
  }
}
resource "aws_ecs_task_definition" "django_app" {
  container_definitions    = data.template_file.django_app.rendered
  family                   = var.project_name
  requires_compatibilities = [var.launch_type]
  task_role_arn            = aws_iam_role.app_execution_role.arn
  execution_role_arn       = aws_iam_role.app_execution_role.arn

  cpu          = "256"
  memory       = "512"
  network_mode = "awsvpc"
}




# Postgres database RDS
resource "aws_db_instance" "app_rds" {
  identifier                = "${var.project_name}-1-rds"
  allocated_storage         = var.rds_allocated_storage
  engine                    = var.rds_engine
  engine_version            = var.rds_engine_version
  instance_class            = var.rds_instance_class
  username                  = var.database_user
  password                  = var.database_password
  vpc_security_group_ids    = data.aws_security_groups.app_sg.ids
  storage_type              = var.rds_storage_type
  db_subnet_group_name      = "main"
  skip_final_snapshot       = true
}


# # IAM roles
resource "aws_iam_role" "app_execution_role" {
  name               = "${var.project_name}-execution-role-1"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}
