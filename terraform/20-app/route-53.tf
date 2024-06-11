module "route_53_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "3.1.0"

  zone_id = local.account_layer.dns.account.zone_id

  records = [
    {
      name  = local.environment
      type  = "A"
      alias = {
        name    = module.cloudfront_front_end.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_front_end.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name  = "${local.environment}-lb"
      type  = "A"
      alias = {
        name    = module.front_end_alb.dns_name
        zone_id = module.front_end_alb.zone_id
      }
    },
    {
      name  = "${local.environment}-api"
      type  = "A"
      alias = {
        name    = module.cloudfront_public_api.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_public_api.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name  = "${local.environment}-api-lb"
      type  = "A"
      alias = {
        name    = module.public_api_alb.dns_name
        zone_id = module.public_api_alb.zone_id
      }
    },
    {
      name  = "${local.environment}-private-api",
      type  = "A"
      alias = {
        name    = module.private_api_alb.dns_name
        zone_id = module.private_api_alb.zone_id
      }
    },
    {
      name  = "${local.environment}-feedback-api",
      type  = "A"
      alias = {
        name    = module.feedback_api_alb.dns_name
        zone_id = module.feedback_api_alb.zone_id
      }
    },
    {
      name  = "${local.environment}-cms"
      type  = "A"
      alias = {
        name    = module.cms_admin_alb.dns_name
        zone_id = module.cms_admin_alb.zone_id
      }
    },
    {
      name  = "${local.environment}-archive"
      type  = "A"
      alias = {
        name    = module.cloudfront_archive_web_content.cloudfront_distribution_domain_name
        zone_id = module.cloudfront_archive_web_content.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name  = "${local.environment}-feature-flags"
      type  = "A"
      alias = {
        name    = module.feature_flags_alb.dns_name
        zone_id = module.feature_flags_alb.zone_id
      }
    }
  ]
}

