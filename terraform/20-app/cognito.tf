resource "aws_iam_role" "cognito_sns_role" {
  name = "cognito-sns-role-${terraform.workspace}"

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
  name = "app-${local.prefix}-cognito-sms-topic"
}

resource "aws_iam_policy" "cognito_sns_policy" {
  name = "app-${local.prefix}-cognito-sns-policy"

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
  user_pool_name    = "app-${local.prefix}-user-pool"
  client_name       = "app-${local.prefix}-client"
  user_pool_domain  = "app-${local.prefix}-domain"
  callback_urls     = ["https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk/callback"]
  logout_urls       = ["https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk/logout"]

  nhs_metadata_url         = "https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk/nhs-metadata.xml"
  cobr_oidc_client_id      = "cobr-client-id"
  cobr_oidc_client_secret  = "cobr-client-secret"
  cobr_oidc_issuer_url     = "https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk/cobr-issuer"
  cobr_oidc_attributes_url = "https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk/attributes"
  region                   = local.region
}

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "app-${local.prefix}-security-group"
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