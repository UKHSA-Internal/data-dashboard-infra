module "iam_observability_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.6.0"

  create_role          = local.is_dev
  max_session_duration = 43200
  role_name            = "Observability"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    module.iam_cloudwatch_readonly_policy.arn
  ]

  trusted_role_arns = compact([
    "arn:aws:iam::943339978990:role/observability-bridge-role"
  ])
}

module "iam_cloudwatch_readonly_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.0"

  create_policy = local.is_dev
  name        = "ObservabilityReadOnly"
  description = "Allows Read Only access to selected cloudwatch metrics and logs"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid = "CloudwatchMetrics",
        Effect = "Allow",
        Action =  [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ],
        Resource = "*"
      },
      {
        Sid = "CloudwatchLogs",
        Effect = "Allow",
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents",
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:GetLogRecord",
          "logs:StopQuery"
        ],
        Resource = "*"
      }
    ]
  })
}
