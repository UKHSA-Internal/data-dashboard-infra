resource "random_password" "private_api_key_prefix" {
  length      = 8
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  special     = false
}

resource "random_password" "private_api_key_suffix" {
  length      = 32
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  special     = false
}

resource "random_password" "backend_application_secret_key" {
  length      = 50
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  special     = true
}

locals {
  private_api_key = "${random_password.private_api_key_prefix.result}.${random_password.private_api_key_suffix.result}"
}
