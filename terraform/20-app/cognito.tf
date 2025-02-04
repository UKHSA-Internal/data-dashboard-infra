resource "aws_iam_role" "cognito_sns_role" {
  name = "${local.prefix}-cognito-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_sns_topic" "cognito_topic" {
  name = "${local.prefix}-cognito-sms-topic"
}

resource "aws_iam_policy" "cognito_sns_policy" {
  name = "${local.prefix}-cognito-sns-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.cognito_topic.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_sns_policy_attachment" {
  role       = aws_iam_role.cognito_sns_role.name
  policy_arn = aws_iam_policy.cognito_sns_policy.arn
}

module "cognito" {
  source = "../modules/cognito"

  sns_role_arn = aws_iam_role.cognito_sns_role.arn
  user_pool_name    = "${local.prefix}-user-pool"
  client_name       = "${local.prefix}-client"
  user_pool_domain  = "${local.prefix}-domain"
  callback_urls     = ["https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk/api/auth/callback/cognito", "http://localhost:3000/api/auth/callback/cognito", "http://localhost:3001/api/auth/callback/cognito"]
  logout_urls       = ["https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk", "http://localhost:3000", "http://localhost:3001"]
  region = local.region

  # Placeholder for SAML metadata URL, used only when SAML is enabled
  # we will need to add multiple metadata_urls e.g. cobr_metadata_url and nhs_metadata_url for each provider
  metadata_url = "https://example.com/metadata.xml"

  # Placeholder for OIDC configuration, used only when OIDC is enabled
  # we will need to add multiple variables e.g. cobr_oidc_client_id and nhs_oidc_client_id for each provider
  oidc_client_id      = "oidc-client-id"
  oidc_client_secret  = "oidc-client-secret"
  oidc_issuer_url     = "https://example.com/issuer"
  oidc_attributes_url = "https://example.com/attributes"

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