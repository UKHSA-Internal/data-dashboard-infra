output "ecs" {
  value = {
    cluster_name = module.ecs.cluster_name
    service_names = {
      cms_admin   = module.ecs_service_cms_admin.name
      private_api = module.ecs_service_private_api.name
      public_api  = module.ecs_service_public_api.name
      front_end   = module.ecs_service_front_end.name
    }
  }
}

output "passwords" {
  value = {
    rds_db_password         = random_password.rds_db_password.result
    private_api_key         = local.private_api_key
    cms_admin_user_password = random_password.cms_admin_user_password.result
  }
  sensitive = true
}

locals {
  urls = contains(concat(local.wke.account, local.wke.other), local.environment) ? {
    front_end   = "https://${local.account_layer.dns.wke_dns_names[local.environment]}"
    cms_admin   = "https://cms.${local.account_layer.dns.wke_dns_names[local.environment]}"
    public_api  = "https://api.${local.account_layer.dns.wke_dns_names[local.environment]}"
    private_api = "http://${module.private_api_alb.lb_dns_name}"
    } : {
    front_end   = "https://${local.environment}.${local.account_layer.dns.account.dns_name}"
    cms_admin   = "https://${local.environment}-cms.${local.account_layer.dns.account.dns_name}"
    public_api  = "https://${local.environment}-api.${local.account_layer.dns.account.dns_name}"
    private_api = "http://${module.private_api_alb.lb_dns_name}"
  }
}

output "urls" {
  value = local.urls
}
