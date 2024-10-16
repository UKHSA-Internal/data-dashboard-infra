module "s3_canary_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = "${local.prefix}-canary-logs"

  attach_deny_insecure_transport_policy = true
  force_destroy                         = true

  logging = {
    target_bucket = data.aws_s3_bucket.s3_access_logs.id
    target_prefix = "${local.prefix}-canary-logs/"
  }

  lifecycle_rule = [
    {
      id      = "all"
      enabled = true
      expiration = {
        days = 7
      }
    }
  ]
}
