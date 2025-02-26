data "aws_secretsmanager_secret" "ukhsa_oidc_credentials" {
  name = "${local.prefix}-ukhsa-oidc-credentials"
}

data "aws_secretsmanager_secret_version" "ukhsa_oidc_credentials" {
  secret_id = data.aws_secretsmanager_secret.ukhsa_oidc_credentials.id
}

data "aws_secretsmanager_secret" "ukhsa_tenant_id" {
  name = "${local.prefix}-ukhsa-tenant-id"
}

data "aws_secretsmanager_secret_version" "ukhsa_tenant_id" {
  secret_id = data.aws_secretsmanager_secret.ukhsa_tenant_id.id
}

locals {
  # Retrieve values from Secrets Manager
  ukhsa_oidc_credentials = try(jsondecode(data.aws_secretsmanager_secret_version.ukhsa_oidc_credentials.secret_string), {})
  ukhsa_tenant_id        = try(jsondecode(data.aws_secretsmanager_secret_version.ukhsa_tenant_id.secret_string)["tenant_id"], "")

  # Ensure correct retrieval of OIDC credentials
  ukhsa_oidc_client_id     = lookup(local.ukhsa_oidc_credentials, "client_id", "")
  ukhsa_oidc_client_secret = lookup(local.ukhsa_oidc_credentials, "client_secret", "")

  # Define callback and logout URLs
  default_callback_urls = ["https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk/api/auth/callback/cognito"]
  default_logout_urls   = ["https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk"]

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
  ukhsa_tenant_id     = local.ukhsa_tenant_id
  ukhsa_oidc_client_id      = local.ukhsa_oidc_client_id
  ukhsa_oidc_client_secret  = local.ukhsa_oidc_client_secret

  lambda_role_arn     = aws_iam_role.cognito_lambda_role.arn
  prefix             = local.prefix
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.cognito_user_pool_id
  sensitive   = true
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito.cognito_user_pool_client_id
  sensitive   = true
}