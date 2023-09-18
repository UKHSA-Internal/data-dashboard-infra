module "route_53_records_wke_others" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.10.2"

  create  = contains(local.wke.other, local.environment)
  zone_id = contains(local.wke.other, local.environment) ? local.account_layer.dns.wke[local.environment].zone_id : ""

  records = [
    {
      name = ""
      type = "A"
      alias = {
        name    = module.cloudfront_front_end.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_front_end.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name = "lb"
      type = "A"
      alias = {
        name    = module.front_end_alb.lb_dns_name
        zone_id = module.front_end_alb.lb_zone_id
      }
    },
    {
      name = "api"
      type = "A"
      alias = {
        name    = module.cloudfront_front_end.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_front_end.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name = "api-lb"
      type = "A"
      alias = {
        name    = module.front_end_alb.lb_dns_name
        zone_id = module.front_end_alb.lb_zone_id
      }
    },
    {
      name = "private-api"
      type = "A"
      alias = {
        name    = module.private_api_alb.lb_dns_name
        zone_id = module.private_api_alb.lb_zone_id
      }
    },
    {
      name = "cms"
      type = "A"
      alias = {
        name    = module.cms_admin_alb.lb_dns_name
        zone_id = module.cms_admin_alb.lb_zone_id
      }
    }
  ]
}
