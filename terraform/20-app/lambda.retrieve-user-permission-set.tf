module "lambda_retrieve_user_permission_set" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "8.8.0"
  function_name = "${local.prefix}-retrieve-user-permission-set"
  description   = "Populate cognito token with user permission sets"

  cloudwatch_logs_retention_in_days = local.default_log_retention_in_days

  create_package = true
  runtime        = "nodejs24.x"
  handler        = "index.handler"
  source_path    = "../../src/lambda-retrieve-user-permission-set"

  maximum_retry_attempts = 1
  timeout                = 60 # Timeout after 1 minute

  architectures = ["arm64"]

  environment_variables = {
    SECRETS_MANAGER_PRIVATE_API_KEY_ARN = aws_secretsmanager_secret.private_api_key.arn
    PRIVATE_API_URL                     = local.urls.private_api
  }

  attach_policy_statements = true
  policy_statements = {
    get_private_api_key_from_secrets_manager = {
      effect    = "Allow",
      actions   = ["secretsmanager:GetSecretValue"],
      resources = [aws_secretsmanager_secret.private_api_key.arn]
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

resource "aws_lambda_permission" "lambda_retrieve_user_permission_set" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_retrieve_user_permission_set.lambda_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = "arn:aws:cognito-idp:${local.region}:${data.aws_caller_identity.current.account_id}:userpool/*"
}
