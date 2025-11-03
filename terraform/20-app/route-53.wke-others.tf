module "route_53_records_wke_others" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "6.1.1"

  create  = contains(local.wke.other, local.environment)
  zone_id = contains(local.wke.other, local.environment) ? local.account_layer.dns.wke[local.environment].zone_id : ""

  records = [
    {
      name  = ""
      type  = "A"
      alias = {
        name    = module.cloudfront_front_end.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_front_end.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name  = "lb"
      type  = "A"
      alias = {
        name    = module.front_end_alb.dns_name
        zone_id = module.front_end_alb.zone_id
      }
    },
    {
      name  = "api"
      type  = "A"
      alias = {
        name    = module.cloudfront_front_end.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_front_end.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name  = "api-lb"
      type  = "A"
      alias = {
        name    = module.public_api_alb.dns_name
        zone_id = module.public_api_alb.zone_id
      }
    },
    {
      name  = "private-api"
      type  = "A"
      alias = {
        name    = module.private_api_alb.dns_name
        zone_id = module.private_api_alb.zone_id
      }
    },
    {
      name  = "feedback-api"
      type  = "A"
      alias = {
        name    = module.feedback_api_alb.dns_name
        zone_id = module.feedback_api_alb.zone_id
      }
    },
    {
      name  = "cms"
      type  = "A"
      alias = {
        name    = module.cms_admin_alb.dns_name
        zone_id = module.cms_admin_alb.zone_id
      }
    },
    {
      name  = "archive"
      type  = "A"
      alias = {
        name    = module.cloudfront_archive_web_content.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_archive_web_content.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name  = "feature-flags"
      type  = "A"
      alias = {
        name    = module.feature_flags_alb.dns_name
        zone_id = module.feature_flags_alb.zone_id
      }
    }
  ]
}
