resource "aws_ses_domain_identity" "sender" {
  domain = local.dns_names.emails
}

resource "aws_ses_domain_dkim" "sender" {
  domain = aws_ses_domain_identity.sender.domain
}
