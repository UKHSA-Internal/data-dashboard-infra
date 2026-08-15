module "lambda_retrieve_user_permission_set" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.8.1"
  function_name = "${local.prefix}-retrieve-user-permission-set"
  description   = "Populate cognito token with user permission sets"

  cloudwatch_logs_retention_in_days = local.default_log_retention_in_days

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.lambda_retrieve_user_permission_set_security_group.security_group_id]
  attach_network_policy  = true

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
      effect  = "Allow"
      actions = ["kms:Decrypt"]
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

module "lambda_retrieve_user_permission_set_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name   = "${local.prefix}-lambda-retrieve-user-permission-set"
  vpc_id = module.vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      description = "https to internet (private API ALB via VPC / Secrets Manager via NAT)"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
