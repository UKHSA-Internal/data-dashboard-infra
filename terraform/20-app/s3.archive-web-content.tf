locals {
  s3_archive_web_content_bucket_name = "${local.prefix}-archive-web-content"
}

module "s3_archive_web_content" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

  bucket = local.s3_archive_web_content_bucket_name

  attach_deny_insecure_transport_policy = true
  attach_policy                         = true
  force_destroy                         = true

  logging = {
    target_bucket = data.aws_s3_bucket.s3_access_logs.id
    target_prefix = "${local.s3_archive_web_content_bucket_name}/"
  }

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action = [
          "s3:GetObject",
        ],
        Resource = "arn:aws:s3:::${local.s3_archive_web_content_bucket_name}/*",
        Condition = {
          StringEquals = {
            "aws:SourceArn" : module.cloudfront_archive_web_content.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}
