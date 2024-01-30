resource "aws_secretsmanager_secret" "sentinel_external_id" {
  name = "sentinel/external-id"
}

resource "aws_secretsmanager_secret" "splunk_cloudwatch_logs_token" {
  name = "splunk/cloudwatch-logs/hec-token"
}

resource "aws_secretsmanager_secret" "splunk_cloudwatch_metrics_token" {
  name = "splunk/cloudwatch-metrics/hec-token"
}

data "aws_secretsmanager_secret_version" "splunk_cloudwatch_logs_token" {
  secret_id = aws_secretsmanager_secret.splunk_cloudwatch_logs_token.arn
}

data "aws_secretsmanager_secret_version" "splunk_cloudwatch_metrics_token" {
  secret_id = aws_secretsmanager_secret.splunk_cloudwatch_metrics_token.arn
}
