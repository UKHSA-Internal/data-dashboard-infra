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
    api_key                 = local.api_key
    api_admin_user_password = random_password.api_admin_user_password.result
  }
  sensitive = true
}

output "urls" {
  value = {
    front_end = "http://${module.front_end_alb.lb_dns_name}"
    api       = "http://${module.api_alb.lb_dns_name}"
  }
}
