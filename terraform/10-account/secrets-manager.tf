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
    ENTRA_ALLOWED_APP_IDS    = "REPLACE_ME,REPLACE_ME"
    ENTRA_TENANT_ID = "REPLACE ME"
  })
}

################################################################################
# OS GDN map credentials
################################################################################

# Deprecated secret
resource "aws_secretsmanager_secret" "os_gdn_api_key" {
  name        = "os-gdn-api-key"
  description = "This is the API key required for the OS GDN maps service."
  kms_key_id  = module.kms_secrets.key_id
}

resource "aws_secretsmanager_secret_version" "os_gdn_api_key" {
  secret_id = aws_secretsmanager_secret.os_gdn_api_key.id
  secret_string = jsonencode({
    PROJECT_API_KEY = "",
    PROJECT_API_SECRET = ""
  })
}
