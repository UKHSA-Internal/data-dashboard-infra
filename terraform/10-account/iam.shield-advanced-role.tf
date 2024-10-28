module "shield_advanced_drt_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.47.1"

  create_role          = true
  max_session_duration = 43200
  role_name            = "ShieldAdvancedDRTRole"
  role_requires_mfa    = false

  custom_role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"]
  trusted_role_services   = ["drt.shield.amazonaws.com"]
}
