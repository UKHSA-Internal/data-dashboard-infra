
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

variable "subnet_id_1" {default = "subnet-021cb27db0cd8d3e8"}
variable "subnet_id_2" {default = "subnet-078da0d9d54aeed64"}
variable "subnet_id_3" {default = "subnet-0b9f20fcc12e0d218"}

variable "subnet_id_4" {default = "subnet-0e46d470a44e33e79"}
variable "subnet_id_5" {default = "subnet-0cdf4e1f4de658548"}
variable "subnet_id_6" {default = "subnet-05b6ba72b4bd1d1b4"}

variable "subnet_id_7" {default = "subnet-0b3dd195a9f7ade77"}


