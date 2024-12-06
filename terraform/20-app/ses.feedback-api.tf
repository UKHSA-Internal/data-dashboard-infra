data "aws_secretsmanager_secret_version" "private_api_email_credentials" {
  secret_id = aws_secretsmanager_secret.private_api_email_credentials.id
}

locals {
  email_credentials = jsondecode(data.aws_secretsmanager_secret_version.private_api_email_credentials.secret_string)
}

resource "aws_ses_email_identity" "sender" {
  email = local.email_credentials["feedback_email_recipient_address"]
}

resource "aws_ses_email_identity" "recipient" {
  email = local.email_credentials["email_host_user"]
}
