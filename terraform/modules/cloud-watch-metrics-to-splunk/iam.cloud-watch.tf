module "iam_cloud_watch_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.37.0"

  create_role          = var.create
  max_session_duration = 3600
  role_name            = "cloud-watch-metrics-streaming-role-${local.region}"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    module.iam_cloud_watch_metrics_policy.arn
  ]

  trusted_role_services = [
    "streams.metrics.cloudwatch.amazonaws.com"
  ]
}

module "iam_cloud_watch_metrics_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.37.0"

  create_policy = var.create
  name          = "cloud-watch-metrics-streaming-policy-${local.region}"

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
          Resource = aws_kinesis_firehose_delivery_stream.splunk[0].arn
        }
      ]
    }
  )
}
