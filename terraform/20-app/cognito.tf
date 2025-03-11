data "aws_secretsmanager_secret" "cognito_service_credentials" {
  name = "${local.prefix}-cognito-service-credentials"
}

data "aws_secretsmanager_secret_version" "cognito_service_credentials" {
  secret_id = data.aws_secretsmanager_secret.cognito_service_credentials.id
}

locals {
  decoded_cognito_credentials = jsondecode(data.aws_secretsmanager_secret_version.cognito_service_credentials.secret_string)

  # Define callback and logout URLs
  env_domain_map = {
    dev  = "dev.ukhsa-dashboard.data.gov.uk"
    test = "test.ukhsa-dashboard.data.gov.uk"
    uat  = "uat.ukhsa-dashboard.data.gov.uk"
    prod = "ukhsa-dashboard.data.gov.uk"
  }
  default_callback_urls = [
    "https://${lookup(local.env_domain_map, terraform.workspace, "dev.ukhsa-dashboard.data.gov.uk")}/api/auth/callback/cognito"
  ]
  default_logout_urls = [
    "https://${lookup(local.env_domain_map, terraform.workspace, "dev.ukhsa-dashboard.data.gov.uk")}"
  ]

  dev_callback_urls = terraform.workspace == "dev" ? [
    "http://localhost:3000/api/auth/callback/cognito",
    "http://localhost:3001/api/auth/callback/cognito"
  ] : []

  dev_logout_urls = terraform.workspace == "dev" ? [
    "http://localhost:3000",
    "http://localhost:3001"
  ] : []

  callback_urls = concat(local.default_callback_urls, local.dev_callback_urls)
  logout_urls   = concat(local.default_logout_urls, local.dev_logout_urls)
}

module "cognito" {
  source = "../modules/cognito"
  sns_role_arn        = aws_iam_role.cognito_sns_role.arn
  user_pool_name      = "${local.prefix}-user-pool"
  client_name         = "${local.prefix}-client"
  user_pool_domain    = "${local.prefix}-domain"
  callback_urls       = local.callback_urls
  logout_urls         = local.logout_urls
  region              = local.region

  enable_ukhsa_oidc   = true

  client_id           = local.decoded_cognito_credentials.client_id
  client_secret       = local.decoded_cognito_credentials.client_secret
  ukhsa_tenant_id     = local.decoded_cognito_credentials.tenant_id

  cognito_user_pool_issuer_endpoint = var.cognito_user_pool_issuer_endpoint

  lambda_role_arn     = aws_iam_role.cognito_lambda_role.arn
  prefix              = local.prefix
}