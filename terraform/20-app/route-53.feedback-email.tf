resource "aws_route53_record" "ses_verification" {
  zone_id = local.account_layer.dns.account.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.sender.domain}"
  type    = "TXT"
  ttl     = 300
  records = [aws_ses_domain_identity.sender.verification_token]
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = local.account_layer.dns.account.zone_id
  name    = "${element(aws_ses_domain_dkim.sender.dkim_tokens, count.index)}._domainkey.${aws_ses_domain_identity.sender.domain}"
  type    = "CNAME"
  ttl     = 300
  records = ["${element(aws_ses_domain_dkim.sender.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = local.account_layer.dns.account.zone_id
  name    = "_dmarc.${aws_ses_domain_identity.sender.domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@${aws_ses_domain_identity.sender.domain}"]
}

resource "aws_route53_record" "spf" {
  zone_id = local.account_layer.dns.account.zone_id
  name    = aws_ses_domain_identity.sender.domain
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_mail_from" {
  zone_id = local.account_layer.dns.account.zone_id
  name    = aws_ses_domain_mail_from.sender.mail_from_domain
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "mx_mail_from" {
  zone_id = local.account_layer.dns.account.zone_id
  name    = aws_ses_domain_mail_from.sender.mail_from_domain
  type    = "MX"
  ttl     = 300
  records = ["10 feedback-smtp.${local.region}.amazonses.com"]
}
