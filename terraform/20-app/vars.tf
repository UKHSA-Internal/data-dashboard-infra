variable "assume_account_id" {
  sensitive = true
}

variable "assume_role_name" {
  default = "terraform"
}

variable "azs" {
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "environment_type" {}

variable "one_nat_gateway_per_az" {
  default = false
}

variable "rds_app_db_allocated_storage" {
  default = "20"
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

variable "single_nat_gateway" {
  default = true
}

variable "rds_app_db_instance_class" {
  default = "db.t3.small"
}

variable "rds_app_db_skip_final_snapshot" {
  default = true
}

variable "rds_app_db_storage_type" {
  default = "gp3"
}

variable "halo_account_type" {}
