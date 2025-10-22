module "s3_canary_logs" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "4.5.0"
  create_bucket = var.create

  bucket = "${var.name}-canary-logs"

  attach_deny_insecure_transport_policy = true
  force_destroy                         = true

  logging = {
    target_bucket = var.s3_access_logs_id
    target_prefix = "${var.name}-canary-logs/"
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
