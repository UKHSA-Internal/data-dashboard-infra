module "s3_ingest" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.0"

  bucket = "${local.prefix}-ingest"

  attach_deny_insecure_transport_policy = true

  lifecycle_rule = [
    {
      id      = "processed"
      enabled = true

      filter = {
        prefix = "processed/"
      }

      expiration = {
        days = 30
      }
    }
  ]
}
