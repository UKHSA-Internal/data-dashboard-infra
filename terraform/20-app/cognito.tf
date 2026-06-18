module "cognito" {
  source                = "../modules/cognito"
  user_pool_name        = "${local.prefix}-user-pool"
  client_name           = "${local.prefix}-client"
  client_perf_test_name = "${local.prefix}-client-perf-test"
  user_pool_domain      = "${local.prefix}-domain"
  region                = local.region

  callback_urls = concat(
    ["${local.urls.front_end}/api/auth/callback/cognito"],
      local.is_dev ?
      ["http://localhost:3000/api/auth/callback/cognito", "http://localhost:3001/api/auth/callback/cognito"] : []
  )
  logout_urls = concat(
    [local.urls.front_end, "${local.urls.front_end}/start", "${local.urls.front_end}/logged-out"],
      local.is_dev ? ["http://localhost:3000", "http://localhost:3001", "http://localhost:3000/start", "http://localhost:3001/start"] : []
  )

  enable_ukhsa_oidc = true

  ukhsa_client_id     = var.ukhsa_client_id
  ukhsa_client_secret = var.ukhsa_client_secret
  ukhsa_tenant_id     = var.ukhsa_tenant_id

  prefix          = local.prefix
  is_perf         = local.is_perf

  pre_token_generation_lambda = module.lambda_retrieve_user_permission_set.lambda_function_arn
}
