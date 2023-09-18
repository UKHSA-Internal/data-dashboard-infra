module "s3_elb_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.0"

  bucket = "uhd-aws-elb-access-logs-${local.account_id}-${local.region}"

  attach_deny_insecure_transport_policy = true
  attach_elb_log_delivery_policy        = true
  force_destroy                         = true
}
