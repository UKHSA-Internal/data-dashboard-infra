module "iam_developer_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.52.1"

  create_role          = local.account == "dev"
  max_session_duration = 43200
  role_name            = "Developer"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]

  trusted_role_arns = compact([
    local.sso_role_arns.administrator,
    local.sso_role_arns.developer
  ])
}
