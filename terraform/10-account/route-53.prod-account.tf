module "route_53_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "3.1.0"

  create  = local.account == "prod"
  zone_id = module.route_53_zone_account.route53_zone_zone_id[var.account_dns_name]

  records = [
    {
      name    = "dev"
      type    = "NS"
      ttl     = 300
      records = local.account_states.dev.dns.account.name_servers
    },
    {
      name    = "auth-dev"
      type    = "NS"
      ttl     = 300
      records = local.account_states.auth-dev.dns.account.name_servers
    },
    {
      name    = "test"
      type    = "NS"
      ttl     = 300
      records = local.account_states.test.dns.account.name_servers
    },
    {
      name    = "auth-test"
      type    = "NS"
      ttl     = 300
      records = local.account_states.auth-test.dns.account.name_servers
    },
    {
      name    = "pen"
      type    = "NS"
      ttl     = 300
      records = local.account_states.test.dns.wke.pen.name_servers
    },
    {
      name    = "perf"
      type    = "NS"
      ttl     = 300
      records = local.account_states.test.dns.wke.perf.name_servers
    },
    {
      name    = "uat"
      type    = "NS"
      ttl     = 300
      records = local.account_states.uat.dns.account.name_servers
    },
    {
      name    = "train"
      type    = "NS"
      ttl     = 300
      records = local.account_states.uat.dns.wke.train.name_servers
    },
    {
      name    = "auth-uat"
      type    = "NS"
      ttl     = 300
      records = local.account_states.auth-uat.dns.account.name_servers
    },
  ]
}

module "route_53_records_legacy" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "3.1.0"

  create  = local.account == "prod"
  zone_id = module.route_53_zone_account.route53_zone_zone_id[var.legacy_account_dns_name]

  records = [
    {
      name    = "dev"
      type    = "NS"
      ttl     = 300
      records = local.account_states.dev.dns.legacy.name_servers
    },
    {
      name    = "auth-dev"
      type    = "NS"
      ttl     = 300
      records = local.account_states.auth-dev.dns.legacy.name_servers
    },
    {
      name    = "test"
      type    = "NS"
      ttl     = 300
      records = local.account_states.test.dns.legacy.name_servers
    },
    {
      name    = "auth-test"
      type    = "NS"
      ttl     = 300
      records = local.account_states.auth-test.dns.legacy.name_servers
    },
    {
      name    = "uat"
      type    = "NS"
      ttl     = 300
      records = local.account_states.uat.dns.legacy.name_servers
    },
    {
      name    = "auth-uat"
      type    = "NS"
      ttl     = 300
      records = local.account_states.auth-uat.dns.legacy.name_servers
    }
  ]
}
