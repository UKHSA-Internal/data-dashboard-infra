variable "assume_account_id" {
  sensitive = true
}

variable "assume_role_name" {
  default = "terraform"
}

variable "environment_type" { }
