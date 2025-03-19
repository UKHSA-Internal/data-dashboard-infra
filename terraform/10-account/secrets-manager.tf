resource "aws_secretsmanager_secret" "sentinel_external_id" {
  name       = "sentinel/external-id"
  kms_key_id = module.kms_secrets.key_id
}

resource "aws_secretsmanager_secret_version" "sentinel_external_id" {
  secret_id     = aws_secretsmanager_secret.sentinel_external_id.id
  secret_string = ""
}
