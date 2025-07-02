variable "account_dns_name" {
  type = string
}

variable "assume_account_id" {
  sensitive = true
  type      = string
}

variable "assume_role_name" {
  default = "TerraformOperator"
  type    = string
}

variable "legacy_account_dns_name" {
  type = string
}

variable "tools_account_id" {
  sensitive = true
  type      = string
}

variable "halo_account_type" {
  type = string
}
