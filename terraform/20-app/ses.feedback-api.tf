resource "aws_ses_domain_identity" "sender" {
  domain = local.dns_names.emails
}

resource "aws_ses_domain_identity_verification" "sender" {
  domain     = aws_ses_domain_identity.sender.domain
  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_ses_domain_dkim" "sender" {
  domain = aws_ses_domain_identity.sender.domain
}
