module "route_53_zone_wke_test_account" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "6.1.1"

  create = local.account == "test"

  zones = {
    (local.wke_dns_names.pen)  = {}
    (local.wke_dns_names.perf) = {}
  }
}
