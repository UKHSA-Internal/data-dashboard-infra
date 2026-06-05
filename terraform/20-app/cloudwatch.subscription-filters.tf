resource "time_sleep" "wait_for_public_api_log_group" {
  depends_on      = [module.ecs_service_public_api]
  create_duration = "45s"
}

resource "time_sleep" "wait_for_private_api_log_group" {
  depends_on      = [module.ecs_service_private_api]
  create_duration = "45s"
}

resource "time_sleep" "wait_for_front_end_log_group" {
  depends_on      = [module.ecs_service_front_end]
  create_duration = "45s"
}

resource "time_sleep" "wait_for_cms_admin_log_group" {
  depends_on      = [module.ecs_service_cms_admin]
  create_duration = "45s"
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_public_api_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-public-api"
  log_group_name  = module.ecs_service_public_api.container_definitions.api.cloudwatch_log_group_name
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn

  depends_on = [module.ecs_service_public_api, time_sleep.wait_for_public_api_log_group]
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_private_api_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-private-api"
  log_group_name  = module.ecs_service_private_api.container_definitions.api.cloudwatch_log_group_name
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn

  depends_on = [module.ecs_service_private_api, time_sleep.wait_for_private_api_log_group]
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_frontend_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-frontend"
  log_group_name  = module.ecs_service_front_end.container_definitions.front-end.cloudwatch_log_group_name
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn

  depends_on = [module.ecs_service_front_end, time_sleep.wait_for_front_end_log_group]
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_cms_admin_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-cms}"
  log_group_name  = module.ecs_service_cms_admin.container_definitions.api.cloudwatch_log_group_name
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn

  depends_on = [module.ecs_service_cms_admin, time_sleep.wait_for_cms_admin_log_group]
}
