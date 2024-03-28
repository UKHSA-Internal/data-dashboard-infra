module "iam_kinesis_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.37.2"

  create_role          = true
  max_session_duration = 3600
  role_name            = "kinesis-splunk-cloud-watch-logs-role-${local.region}"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    module.iam_kinesis_policy.arn
  ]

  trusted_role_services = [
    "firehose.amazonaws.com"
  ]
}

module "iam_kinesis_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.37.2"

  name = "kinesis-splunk-cloud-watch-logs-policy-${local.region}"

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ],
          Effect = "Allow",
          Resource = [
            module.s3_kinesis_backup.s3_bucket_arn,
            "${module.s3_kinesis_backup.s3_bucket_arn}/*"
          ]
        },
        {
          Action = [
            "lambda:InvokeFunction",
            "lambda:GetFunctionConfiguration"
          ],
          Effect   = "Allow",
          Resource = "${module.lambda_processor.lambda_function_arn}:$LATEST"
        },
        {
          Action = [
            "kms:GenerateDataKey",
            "kms:Decrypt"
          ],
          Effect   = "Allow",
          Resource = module.kms_splunk.key_arn
        },
        {
          Action = [
            "logs:PutLogEvents"
          ],
          Effect = "Allow",
          Resource = [
            "${aws_cloudwatch_log_group.splunk.arn}:*",
            "${aws_cloudwatch_log_stream.splunk.arn}:*"
          ]
        }
      ]
    }
  )
}
