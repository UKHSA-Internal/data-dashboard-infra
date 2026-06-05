resource "aws_cloudwatch_log_group" "ecs_service_public_api_log_group" {
  name              = "/aws/ecs/${local.prefix}-public-api-auditable/api"
  retention_in_days = local.default_log_retention_in_days
}

resource "aws_cloudwatch_log_group" "ecs_service_private_api_log_group" {
  name              = "/aws/ecs/${local.prefix}-private-api-auditable/api"
  retention_in_days = local.default_log_retention_in_days
}

resource "aws_cloudwatch_log_group" "ecs_service_front_end_log_group" {
  name              = "/aws/ecs/${local.prefix}-front-end-auditable/front-end"
  retention_in_days = local.default_log_retention_in_days
}

resource "aws_cloudwatch_log_group" "ecs_service_cms_admin_log_group" {
  name              = "/aws/ecs/${local.prefix}-cms-admin-auditable/api"
  retention_in_days = local.default_log_retention_in_days
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_public_api_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-public-api"
  log_group_name  = aws_cloudwatch_log_group.ecs_service_public_api_log_group.name
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn

  depends_on = [aws_cloudwatch_log_group.ecs_service_public_api_log_group]
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_private_api_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-private-api"
  log_group_name  = aws_cloudwatch_log_group.ecs_service_private_api_log_group.name
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn

  depends_on = [aws_cloudwatch_log_group.ecs_service_private_api_log_group]
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_frontend_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-frontend"
  log_group_name  = aws_cloudwatch_log_group.ecs_service_front_end_log_group.name
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn

  depends_on = [aws_cloudwatch_log_group.ecs_service_front_end_log_group]
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_cms_admin_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-cms"
  log_group_name  = aws_cloudwatch_log_group.ecs_service_cms_admin_log_group.name
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn

  depends_on = [aws_cloudwatch_log_group.ecs_service_cms_admin_log_group]
}
