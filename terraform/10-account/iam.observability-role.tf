module "iam_observability_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.44.0"

  create_role          = local.create_observability_role
  max_session_duration = 43200
  role_name            = "Observability"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    module.iam_cloudwatch_readonly_policy.arn
  ]

  trusted_role_arns = local.create_observability_role ? [
    for role_name in ["observability-bridge-role", "managed-grafana-workspace-role"] :
    "arn:aws:iam::${local.observability_platform_account_id}:role/${role_name}"
  ] : []
}

module "iam_cloudwatch_readonly_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.44.0"

  create_policy = local.create_observability_role
  name          = "ObservabilityReadOnly"
  description   = "Allows Read Only access to selected cloudwatch metrics and logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "CloudwatchMetrics",
        Effect = "Allow",
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms"
        ],
        Resource = "*"
      },
      {
        Sid    = "CloudwatchLogs",
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
      },
      {
        Sid    = "XRayRead",
        Effect = "Allow",
        Action = [
          "xray:GetTraceSummaries",
          "xray:BatchGetTraces",
          "xray:GetServiceGraph",
          "xray:GetGroups",
          "xray:GetGroup",
          "xray:ListTagsForResource"
        ],
        Resource = "*"
      },
      {
        Sid    = "ResourceDiscovery",
        Effect = "Allow",
        Action = [
          "tag:GetResources",
          "iam:ListAccountAliases"
        ],
        Resource = "*"
      }
    ]
  })
}
