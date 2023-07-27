resource "aws_secretsmanager_secret" "rds_db_creds" {
  name = "${local.prefix}-rds-db-creds"
}

resource "aws_secretsmanager_secret" "cms_api_key" {
  name = "${local.prefix}-cms-api-key"
}

resource "aws_secretsmanager_secret" "cms_admin_user_credentials" {
  name = "${local.prefix}-cms-admin-user-credentials"
}

resource "aws_secretsmanager_secret" "api_secret_key" {
  name = "${local.prefix}-api-secret-key"
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
  secret_string = local.api_key
}

resource "aws_secretsmanager_secret_version" "cms_admin_user_credentials" {
  secret_id = aws_secretsmanager_secret.cms_admin_user_credentials.id
  secret_string = jsonencode({
    username = "testadmin"
    password = random_password.api_admin_user_password.result
  })
}

resource "aws_secretsmanager_secret_version" "api_secret_key" {
  secret_id     = aws_secretsmanager_secret.api_secret_key.id
  secret_string = random_password.api_secret_key.result
}

################################################################################
# Email configuration
################################################################################

resource "aws_secretsmanager_secret" "private_api_email_credentials" {
  name = "${local.prefix}-private-api-email-credentials"
}

resource "aws_secretsmanager_secret_version" "private_api_email_credentials" {
  secret_id = aws_secretsmanager_secret.private_api_email_credentials.id
  secret_string = jsonencode({
    email_host_user                   = ""
    email_host_password               = ""
    feedback_email_recipient_address  = ""
  })
}
