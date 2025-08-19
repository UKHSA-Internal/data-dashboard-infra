module "iam_operations_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.1.1"

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
    local.sso_role_arns.operations,
    ] : [
    local.sso_role_arns.administrator,
    local.sso_role_arns.operations,
  ]
}

module "iam_operations_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.1.1"

  name = "uhd-operations-policy"

  policy = jsonencode(
    {
      Version   = "2012-10-17",
      Statement = [
        {
          Action   = ["s3:PutObject"],
          Effect   = "Allow",
          Resource = "arn:aws:s3:::uhd-*-ingest/in/*.json"
        },
        {
          Action   = ["s3:DeleteObject"],
          Effect   = "Allow",
          Resource = "arn:aws:s3:::uhd-*-ingest/failed/*"
        },
        {
          Action   = ["s3:DeleteObject"],
          Effect   = "Allow",
          Resource = "arn:aws:s3:::uhd-*-ingest/processed/*"
        },
        {
          Action = [
            "cloudfront:CreateInvalidation",
            "cloudfront:GetInvalidation",
            "ecs:DescribeTasks",
            "ecs:ExecuteCommand",
            "ecs:RunTask",
            "logs:StartLiveTail",
            "logs:StopLiveTail"
          ],
          Effect   = "Allow",
          Resource = "*"
        },
        {
          Action = [
            "s3:DeleteObject",
            "s3:GetObject",
            "s3:PutObject",
          ],
          Effect   = "Allow",
          Resource = "arn:aws:s3:::uhd-*-archive-web-content/*"
        }
      ]
    }
  )
}
