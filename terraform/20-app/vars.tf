variable "assume_account_id" {
  sensitive = true
  type      = string
}

variable "assume_role_name" {
  default = "TerraformOperator"
  type    = string
}

variable "azs" {
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  type = list(string)
}

variable "environment_type" {
  type = string
}

variable "one_nat_gateway_per_az" {
  default = false
  type    = string
}

variable "tools_account_id" {
  sensitive = true
  type      = string
}

variable "etl_account_id" {
  sensitive = true
  type      = string
}

variable "ukhsa_tenant_id" {
  sensitive = true
  type      = string
}

variable "ukhsa_client_id" {
  sensitive = true
  type      = string
}

variable "ukhsa_client_secret" {
  sensitive = true
  type      = string
}

variable "single_nat_gateway" {
  default = true
  type    = bool
}

variable "halo_account_type" {
  type = string
}

variable "auth_enabled" {
  type = bool
}

variable "api_gateway_stage_name" {
  description = "The stage name for API Gateway (e.g. dev or live)"
  type        = string
  default     = "dev"
}
