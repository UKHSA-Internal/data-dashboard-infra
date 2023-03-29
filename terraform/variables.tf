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
variable "rds_skip_final_snapshot" {
 type        = bool
 description = "Rds Skip snapshot"
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
variable "rds_cred_arn" {
 type        = string
 description = "arn value of RDS secret"
}
variable "lb_ui_name" {
 type        = string
 description = "Name of the UI loadbalancer"
}
variable "lb_api_name" {
 type        = string
 description = "Name of the API loadbalancer"
}
variable "lb_type" {
 type        = string
 description = "Type of the API/UI loadbalancer"
}
variable "ingress1_port" {
 type        = number
 description = "Loadbalancer security group - Ingress From and To port"
}
variable "ingress1_cidr" {
 type = list(string)
 description = "IPs to whitelist to access loadbalancer on ingress1_port"
}
variable "ingress2_port" {
 type        = number
 description = "Loadbalancer security group - Ingress From and To port"
}
variable "ingress_protocal" {
 type        = string
 description = "Loadbalancer security group - Ingress protocal"
}
variable "ingress2_cidr" {
 type = list(string)
 description = "Allowing traffic out to all IP addresses on ingress blocks 2 and 3- default SG"
}
variable "allowed_sg_list" {
  description = "list of allowed security group to define in Loadbalancer ingress blocks 2 and 3"
  type    = set(string)
}
variable "egress_port" {
 type        = number
 description = "Loadbalancer security group - Egress From and To port"
}
variable "egress_protocal" {
 type        = string
 description = "Loadbalancer security group - Egress protocal"
}
variable "egress_cidr" {
 type = list(string)
 description = "Allowing traffic out to all IP addresses on egress_port"
}
variable "ui_target_group" {
 type = string
 description = "Name of the Front end Target group"
}
variable "ui_targetgroup_port" {
 type        = number
 description = "Front end target group port"
}
variable "ui_targetgroup_protocol" {
 type        = string
 description = "Front end target group protocol"
}
variable "ui_targetgroup_type" {
 type        = string
 description = "Front end target group type"
}
variable "ui_healthcheck_matcher" {
 type        = string
 description = "API health check string matcher"
}
variable "ui_healthcheck_path" {
 type        = string
 description = "Path of the API health check"
}
variable "ui_healthcheck_interval" {
 type        = number
 description = "Interval for API health check"
}
variable "api_target_group" {
 type = string
 description = "Name of the API Target group"
}
variable "api_targetgroup_port" {
 type        = number
 description = "API target group port"
}
variable "api_targetgroup_protocol" {
 type        = string
 description = "API target group protocol"
}
variable "api_targetgroup_type" {
 type        = string
 description = "API target group type"
}
variable "api_healthcheck_matcher" {
 type        = string
 description = "API health check string matcher"
}
variable "api_healthcheck_path" {
 type        = string
 description = "Path of the API health check"
}
variable "api_healthcheck_interval" {
 type        = number
 description = "Interval for API health check"
}
variable "ui_lb_listener_port" {
 type        = string
 description = "Front end load balancer listener port"
}
variable "ui_lb_listener_protocol" {
 type        = string
 description = "Front end load balancer listener protocol"
}
variable "ui_lb_listener_type" {
 type        = string
 description = "Front end load balancer listener default action type"
}
variable "api_lb_listener_port" {
 type        = string
 description = "API load balancer listener port"
}
variable "api_lb_listener_protocol" {
 type        = string
 description = "API load balancer listener protocol"
}
variable "api_lb_listener_type" {
 type        = string
 description = "API load balancer listener default action type"
}
