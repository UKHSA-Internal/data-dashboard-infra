################################################################################
# Feature flags
################################################################################

resource "aws_secretsmanager_secret" "feature_flags_api_keys" {
  name        = "${local.prefix}-feature-flags-api-keys"
  description = "These are the API key required when interacting with the feature flags service."
  kms_key_id  = module.kms_secrets_app_operator.key_id
}

resource "aws_secretsmanager_secret_version" "feature_flags_api_keys" {
  secret_id     = aws_secretsmanager_secret.feature_flags_api_keys.id
  secret_string = jsonencode({
    client_api_key = local.feature_flags_client_api_key
    x_auth         = local.feature_flags_x_auth
  })
}


resource "aws_secretsmanager_secret" "feature_flags_admin_user_credentials" {
  name        = "${local.prefix}-feature-flags-admin-user-credentials"
  description = "These are the default admin credentials required to login to the feature flags application."
  kms_key_id  = module.kms_secrets_app_operator.key_id
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
  kms_key_id  = module.kms_secrets_app_operator.key_id
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
  kms_key_id  = module.kms_secrets_app_engineer.key_id
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
  kms_key_id  = module.kms_secrets_app_engineer.key_id
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
  kms_key_id  = module.kms_secrets_app_engineer.key_id
}

resource "aws_secretsmanager_secret_version" "cdn_front_end_secure_header_value" {
  secret_id     = aws_secretsmanager_secret.cdn_front_end_secure_header_value.id
  secret_string = random_password.cdn_front_end_secure_header_value.result
}

resource "aws_secretsmanager_secret" "cdn_public_api_secure_header_value" {
  name        = "${local.prefix}-cdn-public-api-secure-header-value"
  description = "This is the secure header value for restricting direct access to load balancer in favour of CloudFront"
  kms_key_id  = module.kms_secrets_app_engineer.key_id
}

resource "aws_secretsmanager_secret_version" "cdn_public_api_secure_header_value" {
  secret_id     = aws_secretsmanager_secret.cdn_public_api_secure_header_value.id
  secret_string = random_password.cdn_public_api_secure_header_value.result
}

################################################################################
# Email configuration
################################################################################

resource "aws_secretsmanager_secret" "private_api_email_credentials" {
  name       = "${local.prefix}-private-api-email-credentials"
  kms_key_id = module.kms_secrets_app_engineer.key_id
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
  kms_key_id  = module.kms_secrets_app_operator.key_id
}

resource "aws_secretsmanager_secret_version" "google_analytics_credentials" {
  secret_id     = aws_secretsmanager_secret.google_analytics_credentials.id
  secret_string = jsonencode({
    google_tag_manager_id = ""
  })
}

################################################################################
# Cognito
################################################################################

resource "aws_secretsmanager_secret" "cognito_service_credentials" {
  name        = "${local.prefix}-cognito-service-credentials"
  description = "These are the credentials required for AWS Cognito service."
  kms_key_id  = module.kms_secrets_app_engineer.key_id
}

resource "aws_secretsmanager_secret_version" "cognito_service_credentials" {
  secret_id     = aws_secretsmanager_secret.cognito_service_credentials.id
  secret_string = jsonencode({
    client_url    = module.cognito.cognito_user_pool_issuer_endpoint,
    client_id     = module.cognito.client_id
    client_secret = module.cognito.client_secret
  })
}

################################################################################
# NextAuth
################################################################################

resource "aws_secretsmanager_secret" "auth_secret" {
  name        = "${local.prefix}-auth-secret"
  description = "Used to encrypt the NextAuth.js JWT"
  kms_key_id  = module.kms_secrets_app_operator.key_id
}

resource "aws_secretsmanager_secret_version" "auth_secret" {
  secret_id     = aws_secretsmanager_secret.auth_secret.id
  secret_string = jsonencode({
    auth_secret = local.auth_secret
  })
}

resource "aws_secretsmanager_secret" "revalidate_secret" {
  name        = "${local.prefix}-revalidate-secret"
  description = "Used to support secure cache revalidation in NextAuth.js"
  kms_key_id  = module.kms_secrets_app_operator.key_id
}

resource "aws_secretsmanager_secret_version" "revalidate_secret" {
  secret_id     = aws_secretsmanager_secret.revalidate_secret.id
  secret_string = jsonencode({
    revalidate_secret = random_password.revalidate_secret.result
  })
}

################################################################################
# ESRI maps credentials
################################################################################

# Deprecated secret
resource "aws_secretsmanager_secret" "esri_api_key" {
  name        = "${local.prefix}-esri-api-key"
  description = "This is the API key required for the ESRI maps service."
  kms_key_id  = module.kms_secrets_app_engineer.key_id
}

resource "aws_secretsmanager_secret_version" "esri_api_key" {
  secret_id     = aws_secretsmanager_secret.esri_api_key.id
  secret_string = jsonencode({
    esri_api_key = ""
  })
}

resource "aws_secretsmanager_secret" "esri_maps_service_credentials" {
  name        = "${local.prefix}-esri-maps-service-credentials"
  description = "These are the credentials required for the ESRI maps service."
  kms_key_id  = module.kms_secrets_app_engineer.key_id
}

resource "aws_secretsmanager_secret_version" "esri_maps_service_credentials" {
  secret_id     = aws_secretsmanager_secret.esri_maps_service_credentials.id
  secret_string = jsonencode({
    client_url    = ""
    client_id     = ""
    client_secret = ""
  })
}

################################################################################
# Slack webhook URL
################################################################################

resource "aws_secretsmanager_secret" "slack_webhook_url" {
  name        = "${local.prefix}-slack-webhook-url"
  description = "The Slack webhook URL to be used to post notifications to."
  kms_key_id  = module.kms_secrets_app_engineer.key_id
}

resource "aws_secretsmanager_secret_version" "slack_webhook_url" {
  secret_id     = aws_secretsmanager_secret.slack_webhook_url.id
  secret_string = jsonencode({
    slack_webhook_url = ""
  })
}
