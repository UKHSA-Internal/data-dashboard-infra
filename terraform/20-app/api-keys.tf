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

resource "random_password" "backend_cryptographic_signing_key" {
  length      = 50
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  special     = true
}

resource "random_password" "feature_flags_client_api_key" {
  length      = 56
  min_numeric = 1
  min_lower   = 1
  special     = false
  upper       = false
}

resource "random_password" "feature_flags_admin_user_password" {
  length      = 20
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  min_special = 1
  special     = true
}

locals {
  feature_flags_client_api_key = "*:production.${random_password.feature_flags_client_api_key.result}"
  private_api_key              = "${random_password.private_api_key_prefix.result}.${random_password.private_api_key_suffix.result}"
}
