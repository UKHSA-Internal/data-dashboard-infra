module "route_53_zone_wke_uat_account" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "3.1.0"

  create = local.account == "uat"

  zones = {
    (local.wke_dns_names.train) = {}
  }
}
