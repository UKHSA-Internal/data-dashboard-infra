resource "aws_secretsmanager_secret" "rds_db_creds" {
  name = "${local.prefix}-rds-db-creds"
}

resource "aws_secretsmanager_secret" "private_api_key" {
  name        = "${local.prefix}-private-api-key"
  description = "This is the API key required in request headers when interacting with the private API."

}

resource "aws_secretsmanager_secret" "cms_admin_user_credentials" {
  name        = "${local.prefix}-cms-admin-user-credentials"
  description = "This is the base admin user name and password for the CMS admin application."
}

resource "aws_secretsmanager_secret" "backend_cryptographic_signing_key" {
  name        = "${local.prefix}-backend-cryptographic-signing-key"
  description = "This is the cryptographic signing key used by the backend application only."
}

resource "aws_secretsmanager_secret" "cdn_front_end_secure_header_value" {
  name        = "${local.prefix}-cdn-front-end-secure-header-value"
  description = "This is the secure header value for restricting direct access to load balancer in favour of CloudFront"
}

resource "aws_secretsmanager_secret" "cdn_public_api_secure_header_value" {
  name        = "${local.prefix}-cdn-public-api-secure-header-value"
  description = "This is the secure header value for restricting direct access to load balancer in favour of CloudFront"
}

resource "aws_secretsmanager_secret_version" "rds_db_creds" {
  secret_id = aws_secretsmanager_secret.rds_db_creds.id
  secret_string = jsonencode({
    username = "api_user"
    password = random_password.rds_db_password.result
  })
}

resource "aws_secretsmanager_secret_version" "private_api_key" {
  secret_id     = aws_secretsmanager_secret.private_api_key.id
  secret_string = local.private_api_key
}

resource "aws_secretsmanager_secret_version" "cms_admin_user_credentials" {
  secret_id = aws_secretsmanager_secret.cms_admin_user_credentials.id
  secret_string = jsonencode({
    username = "testadmin"
    password = random_password.cms_admin_user_password.result
  })
}

resource "aws_secretsmanager_secret_version" "backend_cryptographic_signing_key" {
  secret_id     = aws_secretsmanager_secret.backend_cryptographic_signing_key.id
  secret_string = random_password.backend_cryptographic_signing_key.result
}

resource "aws_secretsmanager_secret_version" "cdn_front_end_secure_header_value" {
  secret_id     = aws_secretsmanager_secret.cdn_front_end_secure_header_value.id
  secret_string = random_password.cdn_front_end_secure_header_value.result 
}

resource "aws_secretsmanager_secret_version" "cdn_public_api_secure_header_value" {
  secret_id     = aws_secretsmanager_secret.cdn_public_api_secure_header_value.id
  secret_string = random_password.cdn_public_api_secure_header_value.result
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
