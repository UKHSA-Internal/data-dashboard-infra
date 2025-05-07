module "cognito" {
  source           = "../modules/cognito"
  sns_role_arn     = aws_iam_role.cognito_sns_role.arn
  user_pool_name   = "${local.prefix}-user-pool"
  client_name      = "${local.prefix}-client"
  user_pool_domain = "${local.prefix}-domain"
  region           = local.region

  callback_urls = concat(
    ["${local.urls.front_end}/api/auth/callback/cognito"],
      local.is_dev ?
      ["http://localhost:3000/api/auth/callback/cognito", "http://localhost:3001/api/auth/callback/cognito"] : []
  )
  logout_urls = concat(
    [local.urls.front_end],
      local.is_dev ? ["http://localhost:3000", "http://localhost:3001"] : []
  )

  enable_ukhsa_oidc = true

  ukhsa_client_id     = var.ukhsa_client_id
  ukhsa_client_secret = var.ukhsa_client_secret
  ukhsa_tenant_id     = var.ukhsa_tenant_id

  cognito_user_pool_issuer_endpoint = var.cognito_user_pool_issuer_endpoint

  lambda_role_arn = aws_iam_role.cognito_lambda_role.arn
  prefix          = local.prefix
}