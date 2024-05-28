module "lambda_db_password_rotation" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.2.6"
  function_name = "${local.prefix}-db-password-rotation"
  description   = "Redeploys services which depend on the main database when the password in secrets manager is rotated"

  create_package = true
  runtime        = "nodejs18.x"
  handler        = "index.handler"
  source_path    = "../../src/lambda-db-password-rotation"

  architectures          = ["arm64"]
  maximum_retry_attempts = 1

  environment_variables = {
    ECS_CLUSTER_ARN              = module.ecs.cluster_arn
    DB_PASSWORD_SECRET_ARN       = local.main_db_aurora_password_secret_arn
    CMS_ADMIN_ECS_SERVICE_NAME   = module.ecs_service_cms_admin.name
    PRIVATE_API_ECS_SERVICE_NAME = module.ecs_service_private_api.name
    PUBLIC_API_ECS_SERVICE_NAME  = module.ecs_service_public_api.name
  }

  attach_policy_statements = true
  policy_statements = {
    restart_ecs_services = {
      actions   = ["ecs:UpdateService"]
      effect    = "Allow"
      resources = [
        module.ecs_service_private_api.id,
        module.ecs_service_public_api.id,
        module.ecs_service_cms_admin.id,
      ]
    }
  }

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    allow_eventbridge_trigger = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge.eventbridge_rule_arns["${local.prefix}-db-password-rotation"]
    }
  }
}
