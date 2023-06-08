resource "aws_secretsmanager_secret" "rds_db_creds" {
  name = "${local.prefix}-rds-db-creds"
}

resource "aws_secretsmanager_secret" "cms_api_key" {
  name = "${local.prefix}-cms-api-key"
}

resource "aws_secretsmanager_secret" "cms_admin_user_credentials" {
  name = "${local.prefix}-cms-admin-user-credentials"
}

resource "aws_secretsmanager_secret_version" "rds_db_creds" {
  secret_id = aws_secretsmanager_secret.rds_db_creds.id
  secret_string = jsonencode({
    username = "api_user"
    password = random_password.rds_db_password.result
  })
}

resource "aws_secretsmanager_secret_version" "cms_api_key" {
  secret_id     = aws_secretsmanager_secret.cms_api_key.id
  secret_string = jsonencode({
    password = "${random_password.api_key_prefix.result}.${random_password.api_key_suffix.result}"
  })
}

resource "aws_secretsmanager_secret_version" "cms_admin_user_credentials" {
  secret_id     = aws_secretsmanager_secret.cms_api_key.id
  secret_string = jsonencode({
    username = "testadmin"
    password = random_password.api_admin_user_password.result
  })
}
