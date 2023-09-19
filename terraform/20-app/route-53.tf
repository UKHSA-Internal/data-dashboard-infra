module "route_53_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.10.2"

  zone_id = local.account_layer.dns.account.zone_id

  records = [
    {
      name = local.environment
      type = "A"
      alias = {
        name    = module.cloudfront_front_end.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_front_end.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name = "${local.environment}-lb"
      type = "A"
      alias = {
        name    = module.front_end_alb.lb_dns_name
        zone_id = module.front_end_alb.lb_zone_id
      }
    },
    {
      name = "${local.environment}-api"
      type = "A"
      alias = {
        name    = module.cloudfront_public_api.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_public_api.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name = "${local.environment}-api-lb"
      type = "A"
      alias = {
        name    = module.public_api_alb.lb_dns_name
        zone_id = module.public_api_alb.lb_zone_id
      }
    },
    {
      name = "${local.environment}-private-api",
      type = "A"
      alias = {
        name    = module.private_api_alb.lb_dns_name
        zone_id = module.private_api_alb.lb_zone_id
      }
    },
    {
      name = "${local.environment}-feedback-api",
      type = "A"
      alias = {
        name    = module.feedback_api_alb.lb_dns_name
        zone_id = module.feedback_api_alb.lb_zone_id
      }
    },
    {
      name = "${local.environment}-cms"
      type = "A"
      alias = {
        name    = module.cms_admin_alb.lb_dns_name
        zone_id = module.cms_admin_alb.lb_zone_id
      }
    }
  ]
}

