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
        name    = module.front_end_alb.lb_dns_name
        zone_id = module.front_end_alb.lb_zone_id
      }
    },
    {
      name = "api"
      type = "A"
      alias = {
        name    = module.public_api_alb.lb_dns_name
        zone_id = module.public_api_alb.lb_zone_id
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
