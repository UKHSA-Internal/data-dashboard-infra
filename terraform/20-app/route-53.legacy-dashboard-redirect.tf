module "route_53_records_legacy_dashboard_redirect" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.10.2"

  create = local.environment != "train"

  zone_id = local.account_layer.dns.legacy.zone_id

  records = [
    {
      name = local.environment
      type = "A"
      alias = {
        name    = module.cloudfront_legacy_dashboard_redirect.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_legacy_dashboard_redirect.cloudfront_distribution_hosted_zone_id
      }
    }
  ]
}

module "route_53_records_legacy_dashboard_redirect_wke_account" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.10.2"

  create  = contains(local.wke.account, local.environment) && local.environment != "train"
  zone_id = local.account_layer.dns.legacy.zone_id

  records = [
    {
      name = ""
      type = "A"
      alias = {
        name    = module.cloudfront_legacy_dashboard_redirect.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_legacy_dashboard_redirect.cloudfront_distribution_hosted_zone_id
      }
    }
  ]
}