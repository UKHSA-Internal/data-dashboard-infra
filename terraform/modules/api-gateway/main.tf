data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "api_gateway_lambda" {
  function_name = "${var.prefix}-api-gateway-lambda"
  runtime       = "nodejs18.x"
  role          = var.lambda_role_arn
  handler       = "api_gateway_lambda.handler"

  source_code_hash = filebase64sha256("${path.module}/api_gateway_lambda.zip")
  filename = "${path.module}/api_gateway_lambda.zip"
  timeout  = 15
  publish  = true
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

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = var.name
  description = var.description
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_authorizer" "cognito" {
  name        = "${var.prefix}-cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  type        = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]
}

resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${lookup({
  "live" = aws_lambda_alias.live.arn,
  "dev"  = aws_lambda_alias.dev.arn
}, var.lambda_alias, aws_lambda_alias.live.arn)}/invocations"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.proxy_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  triggers = {
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.api_gateway_stage_name
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  deployment_id = aws_api_gateway_deployment.deployment.id

  description = "Stage for ${var.api_gateway_stage_name}"
  variables = {
    lambda_alias = var.lambda_alias
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn

  depends_on = [
    aws_iam_role.api_gateway_cloudwatch_role,
    aws_iam_role_policy.api_gateway_cloudwatch_policy
  ]
}

resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "${var.prefix}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch_policy" {
  role = aws_iam_role.api_gateway_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "apigateway:GET",
          "apigateway:PUT",
          "apigateway:POST",
          "apigateway:DELETE",
          "apigateway:PATCH"
        ],
        Resource = aws_api_gateway_rest_api.api_gateway.execution_arn
      }
    ]
  })
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

output "api_gateway_lambda_arn" {
  description = "The ARN of the API Gateway Lambda function"
  value       = aws_lambda_function.api_gateway_lambda.arn
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
  validation {
    condition = can(regex("^[a-zA-Z0-9_-]+$", var.prefix))
    error_message = "Prefix must only contain letters, numbers, hyphens, or underscores."
  }
}
