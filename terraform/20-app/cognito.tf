module "cognito" {
  source            = "../modules/cognito"
  sns_role_arn      = aws_iam_role.cognito_sns_role.arn
  user_pool_name    = "${local.prefix}-user-pool"
  client_name       = "${local.prefix}-client"
  user_pool_domain  = "${local.prefix}-domain"

  callback_urls = concat(
    ["${local.urls.front_end}/api/auth/callback/cognito"],
    local.is_dev ? ["http://localhost:3000/api/auth/callback/cognito", "http://localhost:3001/api/auth/callback/cognito"] : []
  )
  logout_urls = concat(
    [local.urls.front_end],
    local.is_dev ? ["http://localhost:3000", "http://localhost:3001"] : []
  )
  region = local.region

  ukhsa_oidc_client_id      = "ukhsa-oidc-client-id"
  ukhsa_oidc_client_secret  = "ukhsa-oidc-client-secret"
  ukhsa_oidc_issuer_url     = "https://example.com/issuer"
  ukhsa_oidc_attributes_url = "https://example.com/attributes"

  lambda_role_arn           = aws_iam_role.cognito_lambda_role.arn
  prefix = local.prefix
}

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.prefix}-security-group"
  description = "Security group for the application"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.aurora_db_app.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]

  tags = {
    project_name = local.project
    env          = terraform.workspace
  }
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.cognito_user_pool_id
  sensitive   = true
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito.cognito_user_pool_client_id
  sensitive   = true
}