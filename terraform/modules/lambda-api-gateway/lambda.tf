resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = "Live alias for API Gateway Lambda"
  function_name    = module.api_gateway_lambda.lambda_function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "dev" {
  name             = "dev"
  description      = "Dev alias for API Gateway Lambda"
  function_name    = module.api_gateway_lambda.lambda_function_name
  function_version = "$LATEST"
}