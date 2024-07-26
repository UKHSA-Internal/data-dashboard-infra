module "cloudwatch_rum_front_end" {
  source      = "../modules/cloudwatch-rum"
  name        = "${local.prefix}-front-end-app-monitor"
  domain_name = local.dns_names.front_end
}
