module "iam_sentinel_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.29.0"

  create_role          = true
  max_session_duration = 3600
  role_name            = "uhd-sentinel-role"
  role_requires_mfa    = false
  role_sts_externalid  = local.account == "prod" ? "5767722a-3166-4a1e-97c3-2ec130dae7d7" : "4e492587-3494-4a66-8654-55fdc4c14f42"

  custom_role_policy_arns = [
    module.iam_sentinel_policy.arn
  ]

  trusted_role_arns = [
    "arn:aws:iam::197857026523:root",
  ]
}

module "iam_sentinel_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.30.0"

  name = "uhd-sentinel-policy"

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "SQS:ChangeMessageVisibility",
            "SQS:DeleteMessage",
            "SQS:ReceiveMessage",
            "SQS:GetQueueUrl"
          ],
          Effect   = "Allow",
          Resource = module.sqs_sentinel_alb_access_logs.queue_arn
        },
        {
          Action = [
            "s3:GetObject"
          ],
          Effect   = "Allow",
          Resource = module.s3_elb_logs.s3_bucket_arn
        }
      ]
    }
  )
}
