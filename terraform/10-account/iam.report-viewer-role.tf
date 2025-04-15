module "iam_report_viewer_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.55.0"

  create_role          = true
  max_session_duration = 43200
  role_name            = "ReportViewer"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/job-function/Billing"
  ]

  trusted_role_arns = [
    local.sso_role_arns.administrator,
    local.sso_role_arns.report_viewer
  ]
}
