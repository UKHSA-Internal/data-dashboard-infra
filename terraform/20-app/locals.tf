locals {
  region      = "eu-west-2"
  project     = "uhd"
  environment = terraform.workspace
  prefix      = "${local.project}-${local.environment}"

  alb_security_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  wke = {
    account = ["dev", "test", "uat", "prod"]
    other   = ["pen", "perf", "train"]
  }
}

locals {
  certificate_arn              = contains(local.wke.other, local.environment) ? local.account_layer.acm.wke[local.environment].certificate_arn : local.account_layer.acm.account.certificate_arn
  cloud_front_certificate_arn  = contains(local.wke.other, local.environment) ? local.account_layer.acm.wke[local.environment].cloud_front_certificate_arn : local.account_layer.acm.account.cloud_front_certificate_arn
  enable_public_db             = local.is_dev
  is_dev                       = var.environment_type == "dev"

  dns_names = contains(concat(local.wke.account, local.wke.other), local.environment) ? {
    cms_admin     = "cms.${local.account_layer.dns.wke_dns_names[local.environment]}"
    front_end     = "${local.account_layer.dns.wke_dns_names[local.environment]}"
    front_end_lb  = "lb.${local.account_layer.dns.wke_dns_names[local.environment]}"
    private_api   = "private-api.${local.account_layer.dns.wke_dns_names[local.environment]}"
    public_api    = "api.${local.account_layer.dns.wke_dns_names[local.environment]}"
    public_api_lb = "api-lb.${local.account_layer.dns.wke_dns_names[local.environment]}"
    } : {
    cms_admin      = "${local.environment}-cms.${local.account_layer.dns.account.dns_name}"
    front_end      = "${local.environment}.${local.account_layer.dns.account.dns_name}"
    front_end_lb   = "${local.environment}-lb.${local.account_layer.dns.account.dns_name}"
    private_api    = "${local.environment}-private-api.${local.account_layer.dns.account.dns_name}"
    public_api     = "${local.environment}-api.${local.account_layer.dns.account.dns_name}"
    public_api_lb  = "${local.environment}-api-lb.${local.account_layer.dns.account.dns_name}"
  }
}
