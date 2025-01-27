resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name

  mfa_configuration = var.enable_mfa ? "ON" : "OFF"

  dynamic "sms_configuration" {
    for_each = var.enable_sms ? [1] : []

    content {
      sns_caller_arn = var.sns_role_arn != null ? var.sns_role_arn : ""
      external_id    = "cognito-sms-external-id"
    }
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  auto_verified_attributes = var.enable_sms ? ["email", "phone_number"] : ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  depends_on = [
    aws_cognito_identity_provider.oidc_idp,
    aws_cognito_identity_provider.saml_idp
  ]

  name         = var.client_name
  user_pool_id = aws_cognito_user_pool.user_pool.id

  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = var.enable_oidc ? ["COGNITO", "TBCSAML", "TBCOIDC"] : ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.user_pool.id

  lifecycle {
    ignore_changes = [domain]
  }
}

# Stubbed SAML Identity Provider
resource "aws_cognito_identity_provider" "saml_idp" {
  count = var.enable_saml ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.user_pool.id
  provider_name = "TBCSAML"
  provider_type = "SAML"

  provider_details = {
    MetadataURL = var.saml_metadata_url != "" ? var.saml_metadata_url : "https://example.com/saml-metadata"
    IDPSignout  = var.saml_logout_url != "" ? var.saml_logout_url : "https://example.com/logout"
  }
}

# Stubbed OIDC Identity Provider
resource "aws_cognito_identity_provider" "oidc_idp" {
  count = var.enable_oidc ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.user_pool.id
  provider_name = "TBCOIDC"
  provider_type = "OIDC"

  provider_details = {
    client_id                     = var.oidc_client_id != "" ? var.oidc_client_id : "stub-client-id"
    client_secret                 = var.oidc_client_secret != "" ? var.oidc_client_secret : "stub-client-secret"
    oidc_issuer                   = var.oidc_issuer_url != "" ? var.oidc_issuer_url : "https://example.com"
    authorize_scopes              = "openid email"
    attributes_request_method     = "GET"
    attributes_url                = var.oidc_attributes_url != "" ? var.oidc_attributes_url : "https://example.com/attributes"
    attributes_url_add_attributes = "true"
  }
}

resource "aws_cognito_user_group" "user_groups" {
  for_each = toset(["Admin", "Analyst", "Viewer"])
  name         = each.value
  user_pool_id = aws_cognito_user_pool.user_pool.id
  precedence = lookup(var.group_precedence, each.value, null)
  description  = "Group for ${each.value} role"
}

