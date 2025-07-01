module "sqs_sentinel_alb_access_logs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.0.0"

  name = "uhd-sentinel-alb-access-logs"

  queue_policy_statements = {
    s3 = {
      actions = [
        "sqs:SendMessage",
      ]
      principals = [
        {
          type        = "Service"
          identifiers = ["s3.amazonaws.com"]
        }
      ]
    }
  }
}
