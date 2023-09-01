output "dns" {
  value = {
    account = {
      zone_id      = module.route_53_zone_account.route53_zone_zone_id[var.account_dns_name]
      name_servers = module.route_53_zone_account.route53_zone_name_servers[var.account_dns_name]
    }
    wke = {
      pen = local.account == "test" ? {
        zone_id      = module.route_53_zone_wke_test_account.route53_zone_zone_id[local.wke_dns_names.pen]
        name_servers = module.route_53_zone_wke_test_account.route53_zone_name_servers[local.wke_dns_names.pen]
      } : null
      perf = local.account == "test" ? {
        zone_id      = module.route_53_zone_wke_test_account.route53_zone_zone_id[local.wke_dns_names.perf]
        name_servers = module.route_53_zone_wke_test_account.route53_zone_name_servers[local.wke_dns_names.perf]
      } : null
      train = local.account == "uat" ? {
        zone_id      = module.route_53_zone_wke_uat_account.route53_zone_zone_id[local.wke_dns_names.train]
        name_servers = module.route_53_zone_wke_uat_account.route53_zone_name_servers[local.wke_dns_names.train]
      } : null
    }
  }
}
