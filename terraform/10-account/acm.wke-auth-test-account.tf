module "acm_wke_auth_perf" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.0.1"

  create_certificate = local.account == "auth-test"

  domain_name = local.wke_dns_names.auth-perf
  zone_id     = local.account == "auth-test" ? module.route_53_zone_wke_auth_test_account.route53_zone_zone_id[local.wke_dns_names.auth-perf] : ""

  subject_alternative_names = [
    "*.${local.wke_dns_names.auth-perf}"
  ]

  validation_method   = "DNS"
  wait_for_validation = true
}
