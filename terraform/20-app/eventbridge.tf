module "eventbridge" {
  source     = "terraform-aws-modules/eventbridge/aws"
  create_bus = false

  rules = {
    "${local.prefix}-db-password-rotation" = {
      description   = "Capture db password rotation event"
      event_pattern = jsonencode({
        source : ["aws.secretsmanager"]
        detail : {
          eventSource : ["secretsmanager.amazonaws.com"],
          eventName : ["RotationSucceeded"]
          additionalEventData : {
            SecretId : [local.main_db_password_secret_arn]
          }
        }
      })
    }
  }

  targets = {
    "${local.prefix}-db-password-rotation" = [
      {
        name = module.lambda_db_password_rotation.lambda_function_name
        arn  = module.lambda_db_password_rotation.lambda_function_arn
      },
    ]
  }
}