module "route_53_zone_wke_test_account" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "3.1.0"

  create = local.account == "test"

  zones = {
    (local.wke_dns_names.pen)  = {}
    (local.wke_dns_names.perf) = {}
  }
}
