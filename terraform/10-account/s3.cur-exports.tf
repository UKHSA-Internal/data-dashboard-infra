locals {
  s3_cur_exports_bucket_name = "uhd-aws-cur-exports-${local.account_id}"

  green_ops_bucket_arn = "arn:aws:s3:::qat-cost-usage-reports"
}

module "s3_cur_exports" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = local.s3_cur_exports_bucket_name

  attach_deny_insecure_transport_policy = true
  attach_policy                         = true
  create_bucket                         = local.ship_cur_to_green_ops_dashboard
  force_destroy                         = true

  replication_configuration = {
    role = module.iam_green_ops_s3_replication_role.iam_role_arn

    rule = {
      delete_marker_replication_status = "Enabled"
      id                               = "green-ops-dashboard"

      destination = {
        bucket = local.green_ops_bucket_arn
      }

      filter = {
        prefix = "cur"
      }
    }
  }

  versioning = {
    enabled = true
  }

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "billingreports.amazonaws.com"
        },
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy"
        ],
        Resource = "arn:aws:s3:::${local.s3_cur_exports_bucket_name}",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" : local.account_id,
            "aws:SourceArn" : "arn:aws:cur:us-east-1:${local.account_id}:definition/*"
          }
        }
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "billingreports.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${local.s3_cur_exports_bucket_name}/*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" : local.account_id,
            "aws:SourceArn" : "arn:aws:cur:us-east-1:${local.account_id}:definition/*"
          }
        }
      }
    ]
  })
}
