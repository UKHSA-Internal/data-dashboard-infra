module "iam_green_ops_s3_replication_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.1"

  create_role          = local.ship_cur_to_green_ops_dashboard
  max_session_duration = 3600
  role_name            = "uhd-green-ops-s3-replication-role"
  role_requires_mfa    = false

  custom_role_policy_arns = [
    module.iam_green_ops_s3_replication_policy.arn
  ]

  trusted_role_arns = [
    "arn:aws:iam::975276445027:root",
  ]

  trusted_role_services = [
    "s3.amazonaws.com"
  ]
}

module "iam_green_ops_s3_replication_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.1"

  create_policy = local.ship_cur_to_green_ops_dashboard
  name          = "uhd-green-ops-s3-replication-policy"

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "s3:ListBucket",
            "s3:GetReplicationConfiguration",
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
          ],
          Effect = "Allow",
          Resource = [
            module.s3_cur_exports.s3_bucket_arn,
            "${module.s3_cur_exports.s3_bucket_arn}/*",
          ]
        },
        {
          Action = [
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags",
          ],
          Effect = "Allow",
          Resource = [
            "${local.green_ops_bucket_arn}/*"
          ]
        }
      ]
    }
  )
}
