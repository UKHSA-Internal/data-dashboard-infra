variable "assume_account_id" {
  sensitive = true
}

variable "assume_role_name" {
  default = "TerraformOperator"
}

variable "azs" {
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "environment_type" {}

variable "one_nat_gateway_per_az" {
  default = false
}

variable "python_version" {}

variable "tools_account_id" {
  sensitive = true
}

variable "etl_account_id" {
  sensitive = true
}

variable "ukhsa_tenant_id" {
  sensitive = true
}

variable "ukhsa_client_id" {
  sensitive = true
}

variable "ukhsa_client_secret" {
  sensitive = true
}

variable "single_nat_gateway" {
  default = true
}

variable "halo_account_type" {}

variable "auth_enabled" {}

variable "api_gateway_stage_name" {
  description = "The stage name for API Gateway (e.g. dev or live)"
  type        = string
  default     = "dev"
}
