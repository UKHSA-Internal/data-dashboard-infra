
# Variables
variable "vpc_id" {default = "vpc-015357d5ad719a7a2"}
variable "project_name" {default = "wp-dashboard"}
variable "launch_type" { default = "FARGATE" }
variable "aws_region" { default = "eu-west-2" }
#
variable "rds_allocated_storage" {default = "10"}
variable "rds_engine" {default = "postgres"}
variable "rds_engine_version" {default = "13.7"}
variable "rds_instance_class" {default = "db.t3.micro"}
variable "rds_storage_type" { default = "standard" }

#
#variable "database_name" {default = "database-2"}
#variable "database_user" {default = "fargate"}
#variable "database_password" {default = ""}
#
variable "docker_image_name" {default = "martinzugnoni/sampleapp"}
variable "docker_image_revision" {default = "0.0.1"}
#