module "api_gateway" {
  source                 = "../modules/api-gateway"
  name                   = "${local.prefix}-api-gateway"
  description            = "API Gateway for ${local.prefix}"
  api_gateway_stage_name = var.api_gateway_stage_name
  lambda_role_arn        = module.cognito.cognito_lambda_role_arn
  cognito_user_pool_arn  = module.cognito.cognito_user_pool_arn
  region                 = local.region
  resource_path_part     = "{proxy+}"

  lambda_function_arn    = module.lambda_api_gateway.lambda_function_arn

  prefix                 = local.prefix
}