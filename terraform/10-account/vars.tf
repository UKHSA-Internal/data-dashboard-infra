variable "assume_account_id" {
  sensitive = true
}

variable "assume_role_name" {
  default = "terraform"
}

variable "tools_account_id" {
  sensitive = true
}
