module "iam_cloud_watch_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.34.0"

  create_role          = true
  max_session_duration = 3600
  role_name            = "cloud-watch-logs-streaming-role-${local.region}"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    module.iam_cloud_watch_metrics_policy.arn
  ]

  trusted_role_services = [
    "logs.amazonaws.com"
  ]
}

module "iam_cloud_watch_metrics_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.34.0"

  name = "cloud-watch-metrics-logs-policy-${local.region}"

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "firehose:PutRecord",
            "firehose:PutRecordBatch"
          ],
          Effect   = "Allow",
          Resource = aws_kinesis_firehose_delivery_stream.splunk.arn
        }
      ]
    }
  )
}
