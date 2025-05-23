data "aws_caller_identity" "current" {}

module "api_gateway_lambda" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.8.1"
  function_name = "${local.prefix}-api-gateway-auth-lambda"
  description   = "Handles API Gateway authentication requests."

  runtime       = "nodejs18.x"
  architectures = ["arm64"]
  handler       = "index.handler"

  create_package = true
  package_type   = "Zip"
  source_path    = "../../src/lambda-api-gateway"

  timeout        = 15
  memory_size    = 128

  cloudwatch_logs_retention_in_days = 7

  environment_variables = {
    SECRET_COGNITO_CREDENTIALS = "${local.prefix}-cognito-service-credentials"
    UKHSA_TENANT_ID            = var.ukhsa_tenant_id
    COGNITO_USER_POOL_ID       = module.cognito.user_pool_id
    UKHSA_CLIENT_ID            = var.ukhsa_client_id
    UKHSA_CLIENT_SECRET        = var.ukhsa_client_secret
  }

  attach_policy_statements = true
  policy_statements = {
    read_secrets_manager = {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [
        aws_secretsmanager_secret.cognito_service_credentials.arn
      ]
    }
    allow_api_gateway_invoke = {
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = ["arn:aws:execute-api:${local.region}:${data.aws_caller_identity.current.account_id}:${module.api_gateway.api_gateway_id}/*/*/*"]
    }
    kms_decrypt = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [
        module.kms_secrets_app_engineer.key_arn
      ]
    }
  }
}