################################################################################
# Main database credentials
################################################################################

resource "aws_secretsmanager_secret" "rds_db_creds" {
  name = "${local.prefix}-rds-db-creds"
}

resource "aws_secretsmanager_secret_version" "rds_db_creds" {
  secret_id     = aws_secretsmanager_secret.rds_db_creds.id
  secret_string = jsonencode({
    username = "api_user"
    password = random_password.rds_db_password.result
  })
}

################################################################################
# Feature flags database credentials
################################################################################

resource "aws_secretsmanager_secret" "aurora_db_feature_flags_credentials" {
  name = "${local.prefix}-aurora-db-feature-flags-credentials"
}

resource "aws_secretsmanager_secret_version" "aurora_db_feature_flags_credentials" {
  secret_id     = aws_secretsmanager_secret.aurora_db_feature_flags_credentials.id
  secret_string = jsonencode({
    username = "unleash_user"
    password = random_password.feature_flags_db_password.result
  })
}

################################################################################
# Feature flags
################################################################################

resource "aws_secretsmanager_secret" "feature_flags_api_keys" {
  name        = "${local.prefix}-feature-flags-api-keys"
  description = "These are the API key required when interacting with the feature flags service."

}

resource "aws_secretsmanager_secret_version" "feature_flags_api_keys" {
  secret_id     = aws_secretsmanager_secret.feature_flags_api_keys.id
  secret_string = jsonencode({
    client_api_key = local.feature_flags_client_api_key
  })
}


resource "aws_secretsmanager_secret" "feature_flags_admin_user_credentials" {
  name        = "${local.prefix}-feature-flags-admin-user-credentials"
  description = "These are the default admin credentials required to login to the feature flags application."

}

resource "aws_secretsmanager_secret_version" "feature_flags_admin_user_credentials" {
  secret_id     = aws_secretsmanager_secret.feature_flags_admin_user_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.feature_flags_admin_user_password.result
  })
}

################################################################################
# CMS admin application credentials
################################################################################

resource "aws_secretsmanager_secret" "cms_admin_user_credentials" {
  name        = "${local.prefix}-cms-admin-user-credentials"
  description = "This is the base admin user name and password for the CMS admin application."
}

resource "aws_secretsmanager_secret_version" "cms_admin_user_credentials" {
  secret_id     = aws_secretsmanager_secret.cms_admin_user_credentials.id
  secret_string = jsonencode({
    username = "testadmin"
    password = random_password.cms_admin_user_password.result
  })
}

################################################################################
# Private API key
################################################################################

resource "aws_secretsmanager_secret" "private_api_key" {
  name        = "${local.prefix}-private-api-key"
  description = "This is the API key required in request headers when interacting with the private API."

}

resource "aws_secretsmanager_secret_version" "private_api_key" {
  secret_id     = aws_secretsmanager_secret.private_api_key.id
  secret_string = local.private_api_key
}

################################################################################
# Backend application cryptographic key
################################################################################

resource "aws_secretsmanager_secret" "backend_cryptographic_signing_key" {
  name        = "${local.prefix}-backend-cryptographic-signing-key"
  description = "This is the cryptographic signing key used by the backend application only."
}

resource "aws_secretsmanager_secret_version" "backend_cryptographic_signing_key" {
  secret_id     = aws_secretsmanager_secret.backend_cryptographic_signing_key.id
  secret_string = random_password.backend_cryptographic_signing_key.result
}

################################################################################
# CDN headers
################################################################################

resource "aws_secretsmanager_secret" "cdn_front_end_secure_header_value" {
  name        = "${local.prefix}-cdn-front-end-secure-header-value"
  description = "This is the secure header value for restricting direct access to load balancer in favour of CloudFront"
}

resource "aws_secretsmanager_secret_version" "cdn_front_end_secure_header_value" {
  secret_id     = aws_secretsmanager_secret.cdn_front_end_secure_header_value.id
  secret_string = random_password.cdn_front_end_secure_header_value.result
}

resource "aws_secretsmanager_secret" "cdn_public_api_secure_header_value" {
  name        = "${local.prefix}-cdn-public-api-secure-header-value"
  description = "This is the secure header value for restricting direct access to load balancer in favour of CloudFront"
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
  secret_id     = aws_secretsmanager_secret.private_api_email_credentials.id
  secret_string = jsonencode({
    email_host_user                  = ""
    email_host_password              = ""
    feedback_email_recipient_address = ""
  })
}

################################################################################
# Google tag manager
################################################################################

resource "aws_secretsmanager_secret" "google_analytics_credentials" {
  name        = "${local.prefix}-google-analytics-credentials"
  description = "These are the credentials associated with the Google Analytics service"
}

resource "aws_secretsmanager_secret_version" "google_analytics_credentials" {
  secret_id     = aws_secretsmanager_secret.google_analytics_credentials.id
  secret_string = jsonencode({
    google_tag_manager_id = ""
  })
}
