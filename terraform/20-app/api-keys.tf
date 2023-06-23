resource "random_password" "api_key_prefix" {
  length      = 8
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  special     = false
}

resource "random_password" "api_key_suffix" {
  length      = 32
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  special     = false
}

locals {
  api_key = "${random_password.api_key_prefix.result}.${random_password.api_key_suffix.result}"
}
