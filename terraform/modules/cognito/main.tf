resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name

  username_attributes = ["email"]

  mfa_configuration = "OFF"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  schema {
    name                = "groups"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }

  schema {
    name                = "entra_oid"
    attribute_data_type = "String"
    mutable             = false
    required            = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  lifecycle {
    ignore_changes = [schema]
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  depends_on = [aws_cognito_identity_provider.ukhsa_oidc_idp]

  name            = var.client_name
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = true

  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["openid", "email", "profile", "aws.cognito.signin.user.admin"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = var.enable_ukhsa_oidc ? ["UKHSAOIDC"] : ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "cognito_user_pool_domain" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.user_pool.id

  lifecycle {
    ignore_changes = [domain]
  }
}

resource "aws_cognito_identity_provider" "ukhsa_oidc_idp" {
  count         = var.enable_ukhsa_oidc ? 1 : 0
  user_pool_id  = aws_cognito_user_pool.user_pool.id
  provider_name = "UKHSAOIDC"
  provider_type = "OIDC"

  provider_details = {
    client_id                 = var.ukhsa_client_id
    client_secret             = var.ukhsa_client_secret
    oidc_issuer               = "https://login.microsoftonline.com/${var.ukhsa_tenant_id}/v2.0"
    authorize_scopes          = "openid email profile"
    attributes_request_method = "GET"
  }

  attribute_mapping = {
    "custom:groups" = "groups"
    "custom:entra_oid" = "oid"
    "name"          = "name"
    "username"      = "sub"
  }
}

resource "aws_cognito_user_group" "cognito_user_groups" {
  for_each = toset(["Admin", "Analyst", "Viewer"])
  name         = each.value
  user_pool_id = aws_cognito_user_pool.user_pool.id
  precedence = lookup(var.group_precedence, each.value, null)
  description  = "Group for ${each.value} role"
}
