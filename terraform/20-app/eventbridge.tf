module "eventbridge" {
  source     = "terraform-aws-modules/eventbridge/aws"
  create_bus = false

  rules = {
    main_db_password_rotation = {
      description   = "Capture main db password rotation"
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
    main_db_password_rotation = [
      {
        name = module.lambda_db_password_rotation.lambda_function_name
        arn  = module.lambda_db_password_rotation.lambda_function_arn
      },
    ]
  }
}