variable "project_name" {
 type        = string
 description = "Name of the project"
 default     = "wp-dashboard-dev"
}
variable "launch_type" {
 type        = string
 description = "hosting platform"
 default     = "FARGATE"
}
variable "aws_region" {
 type        = string
 description = "hosting region"
 default     = "eu-west-2"
}
variable "rds_db_name" {
 type        = string
 description = "Database name"
 default     = "winterpressures"
}
variable "rds_username" {
 type        = string
 description = "Database username"
 default     = "wp_user"
}
variable "rds_allocated_storage" {
 type        = string
 description = "Database storage"
 default     = "10"
}
variable "rds_engine" {
 type        = string
 description = "Database engine"
 default     = "postgres"
}
variable "rds_engine_version" {
 type        = string
 description = "Database engine version"
 default     = "13.7"
}
variable "rds_instance_class" {
 type        = string
 description = "Database instance type"
 default     = "db.t3.micro"
}
variable "rds_storage_type" {
 type        = string
 description = "Database storage type"
 default     = "standard"
}
variable "route_table_id" {
 type        = string
 description = "Route table"
 default     = "rtb-0f58d0af4522bbf9e"
}
variable "vpc_id" {
 type        = string
 description = "VPC"
 default     = "vpc-0043d08600204dc0c"
}
variable "default_sg" {
 type        = string
 description = "Security Group"
 default     = "sg-05032a61e7b440e1b"
}




