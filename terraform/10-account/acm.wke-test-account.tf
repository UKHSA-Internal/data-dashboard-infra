module "acm_wke_pen" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  create_certificate = local.account == "test"

  domain_name = local.wke_dns_names.pen
  zone_id     = local.account == "test" ? module.route_53_zone_wke_test_account.route53_zone_zone_id[local.wke_dns_names.pen] : ""

  subject_alternative_names = [
    "*.${local.wke_dns_names.pen}"
  ]

  wait_for_validation = true
}

module "acm_wke_perf" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  create_certificate = local.account == "test"

  domain_name = local.wke_dns_names.perf
  zone_id     = local.account == "test" ? module.route_53_zone_wke_test_account.route53_zone_zone_id[local.wke_dns_names.perf] : ""

  subject_alternative_names = [
    "*.${local.wke_dns_names.perf}"
  ]

  wait_for_validation = true
}
