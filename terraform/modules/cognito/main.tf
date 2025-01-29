resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name

  mfa_configuration = var.enable_mfa ? "ON" : "OFF"

  lambda_config {
    post_authentication  = aws_lambda_function.cognito_post_auth_lambda.arn
    pre_sign_up          = aws_lambda_function.cognito_pre_signup_lambda.arn
    user_migration       = aws_lambda_function.cognito_user_migration_lambda.arn
  }

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
    aws_cognito_identity_provider.cognito_oidc_idp,
    aws_cognito_identity_provider.cognito_saml_idp
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

resource "aws_cognito_user_pool_domain" "cognito_user_pool_domain" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.user_pool.id

  lifecycle {
    ignore_changes = [domain]
  }
}

# Stubbed SAML Identity Provider
resource "aws_cognito_identity_provider" "cognito_saml_idp" {
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
resource "aws_cognito_identity_provider" "cognito_oidc_idp" {
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

resource "aws_cognito_user_group" "cognito_user_groups" {
  for_each = toset(["Admin", "Analyst", "Viewer"])
  name         = each.value
  user_pool_id = aws_cognito_user_pool.user_pool.id
  precedence = lookup(var.group_precedence, each.value, null)
  description  = "Group for ${each.value} role"
}

resource "aws_lambda_function" "cognito_post_auth_lambda" {
  function_name = "app-${var.prefix}-post-auth-lambda"
  runtime       = "nodejs18.x" # Updated runtime
  role          = aws_iam_role.cognito_lambda_role.arn

  handler       = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/post_auth_lambda.zip")
  filename      = "${path.module}/post_auth_lambda.zip"
  timeout       = 15
}

resource "aws_lambda_function" "cognito_pre_signup_lambda" {
  function_name = "app-${var.prefix}-pre-signup-lambda"
  runtime       = "nodejs18.x" # Updated runtime
  role          = aws_iam_role.cognito_lambda_role.arn

  handler       = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/pre_signup_lambda.zip")
  filename      = "${path.module}/pre_signup_lambda.zip"
  timeout       = 15
}

resource "aws_lambda_function" "cognito_user_migration_lambda" {
  function_name = "app-${var.prefix}-user-migration-lambda"
  runtime       = "nodejs18.x" # Updated runtime
  role          = aws_iam_role.cognito_lambda_role.arn

  handler       = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/user_migration_lambda.zip")
  filename      = "${path.module}/user_migration_lambda.zip"
  timeout       = 15
}

resource "aws_iam_role" "cognito_lambda_role" {
  name = "app-${var.prefix}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cognito_lambda_role_policy" {
  name   = "app-${var.prefix}-lambda-execution-policy"
  role   = aws_iam_role.cognito_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["cognito-idp:PostAuthentication", "cognito-idp:PreSignUp"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = "*"
      }
    ]
  })
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}
