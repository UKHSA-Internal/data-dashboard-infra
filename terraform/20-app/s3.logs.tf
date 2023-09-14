module "s3_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.0"

  bucket                   = "${local.prefix}-logs"
  acl                      = "log-delivery-write"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_deny_insecure_transport_policy = true
  attach_elb_log_delivery_policy        = true
  force_destroy                         = true
}
