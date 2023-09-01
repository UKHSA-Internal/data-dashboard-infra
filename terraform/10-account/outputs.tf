output "dns" {
  value = {
    account = {
      zone_id      = module.route_53_zone_account.route53_zone_zone_id[var.account_dns_name]
      name_servers = module.route_53_zone_account.route53_zone_name_servers[var.account_dns_name]
    }
  }
}
