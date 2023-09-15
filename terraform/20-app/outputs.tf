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
  urls = {
    cms_admin      = "http://${local.dns_names.cms_admin}"
    front_end      = "https://${local.dns_names.front_end}"
    front_end_lb   = "https://${local.dns_names.front_end_lb}"
    private_api    = "https://${local.dns_names.private_api}"
    public_api     = "https://${local.dns_names.public_api}"
    public_api_lb  = "https://${local.dns_names.public_api_lb}"
  }
}

output "urls" {
  value = local.urls
}
