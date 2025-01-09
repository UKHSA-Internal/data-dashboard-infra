resource "aws_ses_domain_identity" "sender" {
  domain = local.dns_names.front_end
}

resource "aws_ses_domain_identity_verification" "sender" {
  domain     = aws_ses_domain_identity.sender.domain
  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_ses_domain_dkim" "sender" {
  domain = aws_ses_domain_identity.sender.domain
}

resource "aws_ses_domain_mail_from" "sender" {
  domain           = aws_ses_domain_identity.sender.domain
  mail_from_domain = "mail.${aws_ses_domain_identity.sender.domain}"
}
