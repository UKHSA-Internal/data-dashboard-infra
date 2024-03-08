module "route_53_zone_account" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.10.2"

  create = true

  zones = {
    (var.account_dns_name)        = {}
    (var.legacy_account_dns_name) = {}
  }
}
