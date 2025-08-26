module "lambda_front_end_revalidation" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "8.1.0"
  function_name = "${local.prefix}-front-end-revalidation"

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.lambda_front_end_revalidation_security_group.security_group_id]
  attach_network_policy  = true

  create_package = true
  runtime        = "nodejs18.x"
  handler        = "index.handler"
  source_path    = "../../src/lambda-front-end-revalidation"

  architectures          = ["arm64"]
  maximum_retry_attempts = 1
  timeout                = 60

  environment_variables = {
    SECRETS_MANAGER_REVALIDATE_SECRET_ARN = aws_secretsmanager_secret.revalidate_secret.arn
    FRONT_END_URL                         = local.urls.front_end
  }

  attach_policy_statements = true
  policy_statements = {
    get_revalidate_secret_from_secrets_manager = {
      effect    = "Allow",
      actions   = ["secretsmanager:GetSecretValue"],
      resources = [aws_secretsmanager_secret.revalidate_secret.arn]
    }
    get_access_to_required_kms_key = {
      effect    = "Allow",
      actions   = ["kms:Decrypt"],
      resources = [module.kms_secrets_app_operator.key_arn]
    }
  }

  create_current_version_allowed_triggers = false
}

module "lambda_front_end_revalidation_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "${local.prefix}-lambda-front-end-revalidation"
  vpc_id = module.vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      description = "https to internet"
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
