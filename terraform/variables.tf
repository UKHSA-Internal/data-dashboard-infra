variable "project_name" {
 type        = string
 description = "Name of the project"
}
variable "launch_type" {
 type        = string
 description = "hosting platform"
}
variable "aws_region" {
 type        = string
 description = "hosting region"
}
variable "rds_db_name" {
 type        = string
 description = "Database name"
}
variable "rds_username" {
 type        = string
 description = "Database username"
}
variable "rds_allocated_storage" {
 type        = string
 description = "Database storage"
}
variable "rds_engine" {
 type        = string
 description = "Database engine"
}
variable "rds_engine_version" {
 type        = string
 description = "Database engine version"
}
variable "rds_instance_class" {
 type        = string
 description = "Database instance type"
}
variable "rds_storage_type" {
 type        = string
 description = "Database storage type"
}
variable "route_table_id" {
 type        = string
 description = "Route table"
}
variable "vpc_id" {
 type        = string
 description = "VPC"
}
variable "default_sg" {
 type        = string
 description = "Security Group"
}
variable "aws_s3_bucket" {
 type        = string
 description = "S3 bucket for UAT incoming"
}
variable "aws_s3_tfbucket" {
 type        = string
 description = "S3 bucket for UAT terraform backend"
}
variable "aws_s3_tfbucket_key" {
 type        = string
 description = "S3 bucket key for UAT terraform backend"
}
variable "rds_subnetgroup_name" {
 type        = string
 description = "Name of the RDS subnet group"
}
variable "lb_ui_name" {
 type        = string
 description = "Name of the UI loadbalancer"
}
variable "lb_api_name" {
 type        = string
 description = "Name of the API loadbalancer"
}
variable "lb_type " {
 type        = string
 description = "Type of the API/UI loadbalancer"
}
