module "eventbridge" {
  source     = "terraform-aws-modules/eventbridge/aws"
  create_bus = false
  role_name  = "${var.name}-eventbridge-role"

  rules = {
    "${var.name}" = {
      description   = "Capture canary run fail"
      event_pattern = jsonencode({
        source : ["aws.synthetics"]
      })
    }
  }

  targets = {
    "${var.name}" = [
      {
        name = var.lambda_function_notification_name
        arn  = var.lambda_function_notification_arn
      },
    ]
  }
}
