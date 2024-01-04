module "route_53_zone_account" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.11.0"

  create = true

  zones = {
    (var.account_dns_name) = {}
  }
}
