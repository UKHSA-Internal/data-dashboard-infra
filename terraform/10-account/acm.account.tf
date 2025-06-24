module "acm_account" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.0"

  domain_name = var.account_dns_name
  zone_id     = module.route_53_zone_account.route53_zone_zone_id[var.account_dns_name]

  subject_alternative_names = [
    "*.${var.account_dns_name}"
  ]

  wait_for_validation = true
}
