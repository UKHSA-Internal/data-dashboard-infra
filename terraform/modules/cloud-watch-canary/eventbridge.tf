module "eventbridge_canary" {
  source     = "terraform-aws-modules/eventbridge/aws"
  version    = "3.17.1"
  create_bus = false
  role_name  = "${var.name}-eventbridge-role"

  rules = {
    (var.name) = {
      description = "Capture failed canary run"
      event_pattern = jsonencode({
        source : ["aws.synthetics"],
        detail : {
          "canary-name" : [aws_synthetics_canary.this.name]
          "test-run-status" : ["FAILED"]
        }
      })
    }
  }

  targets = {
    (var.name) = [
      {
        name = module.lambda_canary_notification.lambda_function_name
        arn  = module.lambda_canary_notification.lambda_function_arn
      },
    ]
  }
}
