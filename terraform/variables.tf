variable "project_name" {default = "wp-dashboard-dev"}
variable "launch_type" {default = "FARGATE" }
variable "aws_region" {default = "eu-west-2"  }
variable "rds_db_name" {default = "winterpressures"}
variable "rds_username" {default = "wp_user"}
variable "rds_allocated_storage" {default = "10"}
variable "rds_engine" {default = "postgres"}
variable "rds_engine_version" {default = "13.7"}
variable "rds_instance_class" {default = "db.t3.micro"}
variable "rds_storage_type" {default = "standard"}
variable "route_table_id" {default = "rtb-0f58d0af4522bbf9e"}
variable "vpc_id" {default = "vpc-0043d08600204dc0c"}
variable "default_sg" {default = "sg-05032a61e7b440e1b"}




