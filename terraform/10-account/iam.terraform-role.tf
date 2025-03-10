module "iam_terraform_role" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version     = "5.53.0"
  create_role = true

  role_name         = "TerraformOperator"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]

  trusted_role_arns = [
    "arn:aws:iam::${var.tools_account_id}:root",
  ]
}
