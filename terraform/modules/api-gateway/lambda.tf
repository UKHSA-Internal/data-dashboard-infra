resource "aws_lambda_function" "api_gateway_lambda" {
  function_name = "${var.prefix}-api-gateway-lambda"
  runtime       = "nodejs18.x"
  role          = var.lambda_role_arn
  handler       = "api_gateway_lambda.handler"

  source_code_hash = filebase64sha256("${path.module}/api_gateway_lambda.zip")
  filename         = "${path.module}/api_gateway_lambda.zip"
  timeout         = 15
  publish         = true
  description     = "Handles API Gateway requests for the ${var.prefix} service"

  environment {
    variables = {
      UKHSA_TENANT_ID = var.ukhsa_tenant_id
    }
  }
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = "Alias pointing to the live version of the Lambda function"
  function_name    = aws_lambda_function.api_gateway_lambda.arn
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "dev" {
  name             = "dev"
  description      = "Alias pointing to the dev version of the Lambda function"
  function_name    = aws_lambda_function.api_gateway_lambda.arn
  function_version = "$LATEST"
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id = "AllowAPIGatewayInvoke"
  action       = "lambda:InvokeFunction"
  function_name = lookup({
    "live" = aws_lambda_alias.live.arn,
    "dev"  = aws_lambda_alias.dev.arn
  }, var.lambda_alias, aws_lambda_alias.live.arn)
  principal  = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api_gateway.id}/*/*/*"
}
