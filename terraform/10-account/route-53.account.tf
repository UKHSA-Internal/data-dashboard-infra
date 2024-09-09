module "route_53_zone_account" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "4.1.0"

  create = true

  zones = {
    (var.account_dns_name)        = {}
    (var.legacy_account_dns_name) = {}
  }
}
