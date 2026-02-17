module "lambda_retrieve_user_permission_set" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "8.5.0"
  function_name = "${local.prefix}-retrieve-user-permission-set"
  description   = "Populate cognito token with user permission sets"

  cloudwatch_logs_retention_in_days = local.default_log_retention_in_days

  create_package = true
  runtime        = "nodejs18.x"
  handler        = "index.handler"
  source_path    = "../../src/lambda-retrieve-user-permission-set"

  maximum_retry_attempts = 1
  timeout                = 60 # Timeout after 1 minute

  architectures = ["arm64"]
}

resource "aws_lambda_permission" "lambda_retrieve_user_permission_set" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_retrieve_user_permission_set.lambda_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = "arn:aws:cognito-idp:${local.region}:${data.aws_caller_identity.current.account_id}:userpool/*"
}
