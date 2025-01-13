module "s3_elb_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.4.0"

  bucket = "uhd-aws-elb-access-logs-${local.account_id}-${local.region}"

  attach_deny_insecure_transport_policy = true
  attach_elb_log_delivery_policy        = true
  force_destroy                         = true
}

module "elb_logs_new_object" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "4.4.0"

  bucket = module.s3_elb_logs.s3_bucket_id

  sqs_notifications = {
    new_object = {
      queue_arn = module.sqs_sentinel_alb_access_logs.queue_arn
      events    = ["s3:ObjectCreated:*"]
    }
  }
}
