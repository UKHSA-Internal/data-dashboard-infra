resource "aws_secretsmanager_secret" "sentinel_external_id" {
  name = "sentinel/external-id"
}
