resource "aws_ses_domain_identity" "sender" {
  domain = local.dns_names.emails
}

resource "aws_ses_domain_dkim" "sender" {
  domain = aws_ses_domain_identity.sender.domain
}

data "aws_secretsmanager_secret_version" "private_api_email_credentials" {
  secret_id = aws_secretsmanager_secret.private_api_email_credentials.id
}

resource "aws_ses_email_identity" "recipient" {
  email = jsondecode(data.aws_secretsmanager_secret_version.private_api_email_credentials.secret_string)["feedback_email_recipient_address"]
}
