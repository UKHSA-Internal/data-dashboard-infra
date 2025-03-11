data "aws_caller_identity" "current" {}

module "api_gateway_lambda" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.8.1"
  function_name = "${local.prefix}-api-gateway-lambda"
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
    SECRET_NAME         = "${local.prefix}-cognito-service-credentials"
    TENANT_SECRET_NAME  = "${local.prefix}-ukhsa-tenant-id"
  }

  attach_policy_statements = true
  policy_statements = {
    read_secrets_manager = {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [
        "arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.account_id}:secret/${local.prefix}-cognito-service-credentials-*",
        "arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.account_id}:secret/${local.prefix}-ukhsa-tenant-id-*"
      ]
    }
    allow_api_gateway_invoke = {
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = ["arn:aws:execute-api:${local.region}:${data.aws_caller_identity.current.account_id}:${module.api_gateway.api_gateway_id}/*/*/*"]
    }
  }
}