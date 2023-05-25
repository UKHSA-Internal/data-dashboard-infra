output "passwords" {
  value = {
    rds_db_password = random_password.rds_db_password.result
  }
  sensitive = true
}

output "urls" {
  value = {
    front_end = "http://${module.front_end_alb.lb_dns_name}"
    api       = "http://${module.api_alb.lb_dns_name}"
  }
}
