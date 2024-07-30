module "iam_canary_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.40.0"

  create_role          = true
  max_session_duration = 3600
  role_name            = var.name
  role_requires_mfa    = false

  custom_role_policy_arns = [module.iam_canary_policy.arn]
  trusted_role_services   = ["lambda.amazonaws.com"]
}

module "iam_canary_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.40.0"

  create_policy = true
  name          = var.name

  policy = jsonencode(
    {
      Version   = "2012-10-17",
      Statement = [
        {
          Action   = ["s3:PutObject"],
          Effect   = "Allow",
          Resource = ["${var.s3_logs_destination.bucket_arn}/*"]
        },
        {
          Action   = ["s3:ListAllMyBuckets"],
          Effect   = "Allow",
          Resource = ["*"]
        },
        {
          Action   = ["cloudwatch:PutMetricData"],
          Effect   = "Allow",
          Resource = ["*"],
          Condition = {
            StringEquals = {
              "cloudwatch:namespace" = "CloudWatchSynthetics"
            }
          }
        },
        {
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
          ]
          Effect   = "Allow",
          Resource = ["*"],
        }
      ]
    }
  )
}
