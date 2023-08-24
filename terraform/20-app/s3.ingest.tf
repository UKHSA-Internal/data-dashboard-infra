module "s3_ingest" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.0"

  bucket = "${local.prefix}-ingest"

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
