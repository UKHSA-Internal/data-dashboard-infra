module "acm_cloud_front" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name = var.account_dns_name
  zone_id     = module.route_53_zone_account.route53_zone_zone_id[var.account_dns_name]

  providers = {
    aws = aws.us_east_1
  }

  subject_alternative_names = [
    "*.${var.account_dns_name}"
  ]

  validation_method   = "DNS"
  wait_for_validation = true
}

module "acm_cloud_front_legacy_dashboard" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name = var.legacy_account_dns_name
  zone_id     = module.route_53_zone_account.route53_zone_zone_id[var.legacy_account_dns_name]

  providers = {
    aws = aws.us_east_1
  }

  subject_alternative_names = [
    "*.${var.legacy_account_dns_name}"
  ]

  validation_method   = "DNS"
  wait_for_validation = true
}
