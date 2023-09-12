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

variable "tools_account_id" {
  sensitive = true
}

variable "single_nat_gateway" {
  default = true
}

# RDS variables

variable "rds_app_db_allocated_storage" {
  default = "20"
}

variable "rds_app_db_engine" {
  default = "postgres"
}

variable "rds_app_db_engine_version" {
  default = "15.3"
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


# Elasticache variables

variable "elasticache_app_node_type" {
  default = "cache.t3.micro"
}


variable "elasticache_app_num_cache_nodes" {
  default = 1
}


variable "elasticache_app_parameter_group_name" {
  default = "default.redis7"
}


variable "elasticache_app_engine_version" {
  default = "7.0"
}


variable "elasticache_app_port" {
  default = 6379
}
