module "iam_sentinel_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.41.0"

  create_role          = true
  max_session_duration = 3600
  role_name            = "uhd-sentinel-role"
  role_requires_mfa    = false
  role_sts_externalid  = data.aws_secretsmanager_secret_version.sentinel_external_id.secret_string

  custom_role_policy_arns = [
    module.iam_sentinel_policy.arn
  ]

  trusted_role_arns = [
    "arn:aws:iam::197857026523:root",
  ]
}

module "iam_sentinel_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.41.0"

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
          Resource = "${module.s3_elb_logs.s3_bucket_arn}/*"
        }
      ]
    }
  )
}

data "aws_secretsmanager_secret_version" "sentinel_external_id" {
  secret_id = aws_secretsmanager_secret.sentinel_external_id.id
}
