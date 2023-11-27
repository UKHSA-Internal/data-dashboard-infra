module "iam_operations_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.29.0"

  create_role          = true
  max_session_duration = 43200
  role_name            = "Operations"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    module.iam_operations_policy.arn
  ]

  trusted_role_arns = local.account == "dev" ? [
    local.sso_role_arns.administrator,
    local.sso_role_arns.developer,
    local.sso_role_arns.operations
    ] : [
    local.sso_role_arns.administrator,
    local.sso_role_arns.operations
  ]
}

module "iam_operations_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"

  name = "uhd-operations-policy"

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "s3:PutObject",
          ],
          Effect   = "Allow",
          Resource = "arn:aws:s3:::uhd-*-ingest/in/*"
        },
        {
          Action = [
            "ecs:RunTask",
            "iam:PassRole",
            "cloudfront:CreateInvalidation",
            "cloudfront:GetInvalidation",
            "ecs:DescribeTasks",
            "logs:StartLiveTail",
            "logs:StopLiveTail"
          ],
          Effect   = "Allow",
          Resource = "*"
        }
      ]
    }
  )
}
