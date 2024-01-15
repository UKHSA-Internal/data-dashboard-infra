module "s3_cloud_front_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.0.1"

  bucket = "uhd-aws-cloud-front-access-logs-${local.account_id}-${local.region}"

  attach_deny_insecure_transport_policy = true
  force_destroy                         = true
  control_object_ownership              = true
  object_ownership                      = "BucketOwnerPreferred"

  grant = [
    {
      type       = "CanonicalUser"
      permission = "FULL_CONTROL"
      id         = data.aws_canonical_user_id.current.id
    },
    {
      type       = "CanonicalUser"
      permission = "FULL_CONTROL"
      id         = data.aws_cloudfront_log_delivery_canonical_user_id.cloudfront.id
    }
  ]

  owner = {
    id = data.aws_canonical_user_id.current.id
  }
}

data "aws_canonical_user_id" "current" {}

data "aws_cloudfront_log_delivery_canonical_user_id" "cloudfront" {}
