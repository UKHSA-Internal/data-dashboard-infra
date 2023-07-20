variable "assume_account_id" {
  sensitive = true
}

variable "assume_role_name" {
  default = "terraform"
}

variable "environment_type" {}

variable "rds_app_db_allocated_storage" {
  default = "10"
}

variable "rds_app_db_engine" {
  default = "postgres"
}

variable "rds_app_db_engine_version" {
  default = "15.3"
}

variable "tools_account_id" {
  sensitive = true
}

variable "rds_app_db_instance_class" {
  default = "db.t3.micro"
}

variable "rds_app_db_skip_final_snapshot" {
  default = true
}

variable "rds_app_db_storage_type" {
  default = "standard"
}
