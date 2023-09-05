output "dns" {
  value = {
    account = {
      zone_id      = module.route_53_zone_account.route53_zone_zone_id[var.account_dns_name]
      name_servers = module.route_53_zone_account.route53_zone_name_servers[var.account_dns_name]
      dns_name     = var.account_dns_name
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

output "acm" {
  value = {
    account = {
      certificate_arn = module.acm_account.acm_certificate_arn
    }
    wke = {
      pen = local.account == "test" ? {
        certificate_arn = module.acm_wke_pen.acm_certificate_arn
      } : null
      perf = local.account == "test" ? {
        certificate_arn = module.acm_wke_perf.acm_certificate_arn
      } : null
      train = local.account == "uat" ? {
        certificate_arn = module.acm_wke_train.acm_certificate_arn
      } : null
    }
  }
}
