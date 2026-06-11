data "aws_secretsmanager_secret" "entra_audience" {
  name = "entra/audience"
}

data "aws_secretsmanager_secret" "entra_tenant_id" {
  name = "entra/tenant-id"
}

data "aws_secretsmanager_secret" "entra_app_id" {
  name = "entra/app-id"
}
