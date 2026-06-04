resource "aws_cloudwatch_log_subscription_filter" "ecs_public_api_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-public-api"
  log_group_name  = "/aws/ecs/${local.prefix}-public-api/api"
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_private_api_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-private-api"
  log_group_name  = "/aws/ecs/${local.prefix}-private-api/api"
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_frontend_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-frontend"
  log_group_name  = "/aws/ecs/${local.prefix}-front-end/front-end"
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn
}

resource "aws_cloudwatch_log_subscription_filter" "ecs_cms_admin_audit_filter" {
  name            = "${local.prefix}-audit-log-filter-cms}"
  log_group_name  = "/aws/ecs/${local.prefix}-cms-admin/api"
  filter_pattern  = "\"[AUDIT_EVENT]\""
  destination_arn = aws_kinesis_firehose_delivery_stream.audit_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_role.arn
}
