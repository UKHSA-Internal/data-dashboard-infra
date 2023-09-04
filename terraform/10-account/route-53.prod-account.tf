module "route_53_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.10.2"

  create  = local.account == "prod"
  zone_id = module.route_53_zone_account.route53_zone_zone_id[var.account_dns_name]

  records = [
    {
      name    = "dev"
      type    = "NS"
      records = local.account_states.dev.dns.account.name_servers
    },
    {
      name    = "test"
      type    = "NS"
      records = local.account_states.test.dns.account.name_servers
    },
    {
      name    = "pen"
      type    = "NS"
      records = local.account_states.test.dns.wke.pen.name_servers
    },
    {
      name    = "perf"
      type    = "NS"
      records = local.account_states.test.dns.wke.perf.name_servers
    },
    {
      name    = "uat"
      type    = "NS"
      records = local.account_states.uat.dns.account.name_servers
    },
    {
      name    = "train"
      type    = "NS"
      records = local.account_states.uat.dns.wke.train.name_servers
    }
  ]
}
