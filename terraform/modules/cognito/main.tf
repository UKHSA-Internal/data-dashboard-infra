data "aws_caller_identity" "current" {}

resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name

  mfa_configuration = "OFF"

  lambda_config {
    pre_authentication   = aws_lambda_function.cognito_pre_auth_lambda.arn
    post_authentication  = aws_lambda_function.cognito_post_auth_lambda.arn
    pre_sign_up          = aws_lambda_function.cognito_pre_signup_lambda.arn
    user_migration       = aws_lambda_function.cognito_user_migration_lambda.arn
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  auto_verified_attributes = []

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
  generate_secret = true

  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["openid", "aws.cognito.signin.user.admin"]

  access_token_validity   = 1    # 1 hour
  id_token_validity       = 1    # 1 hour
  refresh_token_validity  = 720  # 720 hours (30 days)

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

resource "aws_lambda_function" "cognito_pre_auth_lambda" {
  function_name = "${var.prefix}-pre-auth-lambda"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.cognito_lambda_role.arn

  handler       = "pre_auth.handler"
  source_code_hash = filebase64sha256("${path.module}/pre_auth_lambda.zip")
  filename      = "${path.module}/pre_auth_lambda.zip"
  timeout       = 15
  description   = "Handles pre-authentication events in Cognito"
}

resource "aws_lambda_function" "cognito_post_auth_lambda" {
  function_name = "${var.prefix}-post-auth-lambda"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.cognito_lambda_role.arn

  handler       = "post_auth.handler"
  source_code_hash = filebase64sha256("${path.module}/post_auth_lambda.zip")
  filename      = "${path.module}/post_auth_lambda.zip"
  timeout       = 15
  description   = "Handles post-authentication events in Cognito"
}

resource "aws_lambda_function" "cognito_pre_signup_lambda" {
  function_name = "${var.prefix}-pre-signup-lambda"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.cognito_lambda_role.arn

  handler       = "pre_signup.handler"
  source_code_hash = filebase64sha256("${path.module}/pre_signup_lambda.zip")
  filename      = "${path.module}/pre_signup_lambda.zip"
  timeout       = 15
  description   = "Handles pre-signup events in Cognito"
}

resource "aws_lambda_function" "cognito_user_migration_lambda" {
  function_name = "${var.prefix}-user-migration-lambda"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.cognito_lambda_role.arn

  handler       = "user_migration.handler"
  source_code_hash = filebase64sha256("${path.module}/user_migration_lambda.zip")
  filename      = "${path.module}/user_migration_lambda.zip"
  timeout       = 15
  description   = "Handles user migration events in Cognito"
}

resource "aws_iam_role" "cognito_lambda_role" {
  name = "${var.prefix}-lambda-execution-role"

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
  name   = "${var.prefix}-lambda-execution-policy"
  role   = aws_iam_role.cognito_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:DeleteLogStream"
        ],
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.prefix}-*:log-stream:*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "cognito-idp:PostAuthentication",
          "cognito-idp:PreSignUp",
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminInitiateAuth",
          "cognito-idp:ListUsers",
          "cognito-idp:DescribeUserPool",
          "cognito-idp:GetUser",
          "cognito-idp:UpdateUserPoolClient",
          "cognito-idp:AdminGetUser"
        ],
        Resource = "arn:aws:cognito-idp:${var.region}:${data.aws_caller_identity.current.account_id}:userpool/${aws_cognito_user_pool.user_pool.id}"
      },
      {
        Effect   = "Allow",
        Action   = [
          "lambda:InvokeFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ],
        Resource = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix}-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_lambda_basic_exec_attach" {
  role       = aws_iam_role.cognito_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_pre_signup_lambda.arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.user_pool.arn
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}
