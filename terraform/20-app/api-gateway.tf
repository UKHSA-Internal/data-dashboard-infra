module "api_gateway" {
  source                 = "../modules/api-gateway"
  name                   = "${local.prefix}-api-gateway"
  description            = "API Gateway for ${local.prefix}"
  api_gateway_stage_name = var.api_gateway_stage_name
  lambda_role_arn        = module.cognito.cognito_lambda_role_arn
  cognito_user_pool_arn  = module.cognito.cognito_user_pool_arn
  region                 = local.region
  resource_path_part     = "{proxy+}"
  lambda_invoke_arn      = module.api_gateway.lambda_alias_arn
  lambda_function_arn    = module.api_gateway.api_gateway_lambda_arn
  prefix                 = local.prefix
  ukhsa_tenant_id        = var.ukhsa_tenant_id
}