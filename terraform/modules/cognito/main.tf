data "aws_caller_identity" "current" {}

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
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  depends_on = [
    aws_cognito_identity_provider.ukhsa_oidc_idp
  ]

  name         = var.client_name
  user_pool_id = aws_cognito_user_pool.user_pool.id
  generate_secret = true

  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["openid", "email", "profile", "aws.cognito.signin.user.admin"]

  access_token_validity   = 60    # 1 hour
  id_token_validity       = 60    # 1 hour
  refresh_token_validity  = 720  # 720 hours (30 days)

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = var.enable_ukhsa_oidc ? ["COGNITO", "UKHSAOIDC"] : ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "cognito_user_pool_domain" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.user_pool.id

  lifecycle {
    ignore_changes = [domain]
  }
}

resource "aws_cognito_identity_provider" "ukhsa_oidc_idp" {
  count        = var.enable_ukhsa_oidc ? 1 : 0
  user_pool_id = aws_cognito_user_pool.user_pool.id
  provider_name = "UKHSAOIDC"
  provider_type = "OIDC"

  provider_details = {
    client_id                     = var.ukhsa_oidc_client_id
    client_secret                 = var.ukhsa_oidc_client_secret
    oidc_issuer                   = var.ukhsa_oidc_issuer_url
    authorize_scopes              = "openid email"
    attributes_request_method     = "GET"
    attributes_url                = var.ukhsa_oidc_attributes_url
    attributes_url_add_attributes = "true"
  }
}

resource "aws_cognito_user_group" "cognito_user_groups" {
  for_each = toset(["Admin", "Analyst", "Viewer"])
  name         = each.value
  user_pool_id = aws_cognito_user_pool.user_pool.id
  precedence = lookup(var.group_precedence, each.value, null)
  description  = "Group for ${each.value} role"
}

output "cognito_lambda_role_arn" {
  description = "The ARN of the Cognito Lambda execution role"
  value       = var.lambda_role_arn
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}
