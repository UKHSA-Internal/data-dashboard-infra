module "eventbridge" {
  source     = "terraform-aws-modules/eventbridge/aws"
  create_bus = false
  role_name  = "${local.prefix}-eventbridge-role"

  rules = {
    "${local.prefix}-db-password-rotation" = {
      description   = "Capture db password rotation events"
      event_pattern = jsonencode({
        source : ["aws.secretsmanager"]
        detail : {
          eventSource : ["secretsmanager.amazonaws.com"],
          eventName : ["RotationSucceeded"]
          additionalEventData : {
            SecretId : [
              local.main_db_aurora_password_secret_arn,
              local.feature_flags_db_aurora_password_secret_arn,
            ]
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