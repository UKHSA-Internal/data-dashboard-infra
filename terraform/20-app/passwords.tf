resource "random_password" "rds_db_password" {
  length      = 20
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  special     = false
}

resource "random_password" "api_admin_user_password" {
  length = 10
  min_numeric = 1
  min_lower = 1
  min_upper = 1
  special = false
}
