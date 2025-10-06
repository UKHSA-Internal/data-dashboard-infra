module "iam_canary_role" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version     = "5.40.0"
  create_role = var.create

  max_session_duration = 3600
  role_name            = var.name
  role_requires_mfa    = false

  custom_role_policy_arns = [module.iam_canary_policy.arn]
  trusted_role_services = ["lambda.amazonaws.com", "synthetics.amazonaws.com"]
}

module "iam_canary_policy" {
  source        = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version       = "5.40.0"
  create_policy = var.create

  name = var.name

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = ["s3:ListAllMyBuckets"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = ["s3:PutObject"]
          Effect = "Allow"
          Resource = ["${module.s3_canary_logs.s3_bucket_arn}/*"]
        },
        {
          Action = ["s3:GetBucketLocation"]
          Effect = "Allow"
          Resource = [module.s3_canary_logs.s3_bucket_arn]
        },
        {
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeInstances",
            "ec2:AssignPrivateIpAddresses",
            "ec2:UnassignPrivateIpAddresses",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs",
          ]
          Effect = "Allow"
          Resource = ["*"]
        },
        {
          Action = ["cloudwatch:PutMetricData"]
          Effect = "Allow"
          Resource = ["*"]
        },
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect = "Allow"
          Resource = ["*"]
        }
      ]
    }
  )
}
