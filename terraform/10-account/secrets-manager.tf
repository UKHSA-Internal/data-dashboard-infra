resource "aws_secretsmanager_secret" "sentinel_external_id" {
  name       = "sentinel/external-id"
  kms_key_id = module.kms_secrets.key_id
}

resource "aws_secretsmanager_secret" "entra_api_client_config" {
  name       = "entra-api-client-config"
  kms_key_id = module.kms_secrets.key_id
}

resource "aws_secretsmanager_secret_version" "entra_api_client_config_value" {
  secret_id     = aws_secretsmanager_secret.entra_api_client_config.id
  secret_string = jsonencode({
    ENTRA_AUDIENCE  = "REPLACE ME"
    ENTRA_APP_ID    = "REPLACE ME"
    ENTRA_TENANT_ID = "REPLACE ME"
  })
}
