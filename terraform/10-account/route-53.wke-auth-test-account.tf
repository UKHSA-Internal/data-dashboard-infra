module "route_53_zone_wke_auth_test_account" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "6.4.0"

  create = local.account == "auth-test"

  zones = {
    (local.wke_dns_names.auth-perf) = {}
  }
}
