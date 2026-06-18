resource "aws_secretsmanager_secret" "sentinel_external_id" {
  name       = "sentinel/external-id"
  kms_key_id = module.kms_secrets.key_id
}

resource "aws_secretsmanager_secret" "entra_api_client_config" {
  name       = "entra-api-client-config"
  kms_key_id = module.kms_secrets.key_id
}
