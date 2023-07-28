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

output "urls" {
  value = {
    front_end         = "http://${module.front_end_alb.lb_dns_name}"
    cms_admin         = "http://${module.cms_admin_alb.lb_dns_name}"
    private_api       = "http://${module.private_api_alb.lb_dns_name}"
    public_api        = "http://${module.public_api_alb.lb_dns_name}"
  }
}
