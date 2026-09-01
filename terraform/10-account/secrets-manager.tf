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
# UKHSA Azure AD credentials
################################################################################

resource "aws_secretsmanager_secret" "ukhsa_azure_ad_credentials" {
  name        = "ukhsa-azure-ad-credentials"
  description = "This contains the Azure AD (Entra ID) credentials for UKHSA authentication (tenant_id, client_id, client_secret)."
  kms_key_id  = module.kms_secrets.key_id
}

resource "aws_secretsmanager_secret_version" "ukhsa_azure_ad_credentials" {
  secret_id = aws_secretsmanager_secret.ukhsa_azure_ad_credentials.id
  secret_string = jsonencode({
    ukhsa_tenant_id= ""
    ukhsa_client_id = ""
    ukhsa_client_secret = ""
  })
}
