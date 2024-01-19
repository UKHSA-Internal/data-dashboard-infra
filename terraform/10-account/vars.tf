variable "account_dns_name" {}
variable "assume_account_id" {
  sensitive = true
}

variable "assume_role_name" {
  default = "terraform"
}

variable "python_version" {}

variable "tools_account_id" {
  sensitive = true
}
