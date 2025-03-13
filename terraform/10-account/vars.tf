variable "account_dns_name" {}
variable "assume_account_id" {
  sensitive = true
}

variable "assume_role_name" {
  default = "TerraformOperator"
}

variable "legacy_account_dns_name" {}

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

variable "halo_account_type" {}

variable "auth_enabled" {
  default = false
}
