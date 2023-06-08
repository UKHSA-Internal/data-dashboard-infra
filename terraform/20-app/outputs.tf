output "passwords" {
  value = {
    rds_db_password = random_password.rds_db_password.result
    api_key_prefix = random_password.api_key_prefix.result
    api_key_suffix = random_password.api_key_suffix.result
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
