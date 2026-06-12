resource "aws_secretsmanager_secret" "sentinel_external_id" {
  name       = "sentinel/external-id"
  kms_key_id = module.kms_secrets.key_id
}

resource "aws_secretsmanager_secret" "entra_audience" {
  name       = "entra/audience"
  kms_key_id = module.kms_secrets.key_id
}

resource "aws_secretsmanager_secret" "entra_app_id" {
  name       = "entra/app-id"
  kms_key_id = module.kms_secrets.key_id
}

resource "aws_secretsmanager_secret" "entra_tenant_id" {
  name       = "entra/tenant-id"
  kms_key_id = module.kms_secrets.key_id
}
