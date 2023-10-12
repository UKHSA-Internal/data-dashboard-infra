locals {
  region      = "eu-west-2"
  project     = "uhd"
  environment = terraform.workspace
  prefix      = "${local.project}-${local.environment}"

  account_id          = var.assume_account_id
  alb_security_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  use_prod_sizing = contains(["perf", "train", "uat", "prod"], local.environment)

  disable_cloudfront_ttl_prod = false
  prod_cloudfront_min_ttl     = local.disable_cloudfront_ttl_prod ? 0 : 2592000
  prod_cloudfront_max_ttl     = local.disable_cloudfront_ttl_prod ? 0 : 2592000
  prod_cloudfront_default_ttl = local.disable_cloudfront_ttl_prod ? 0 : 2592000

  wke = {
    account = ["dev", "test", "uat", "prod"]
    other   = ["pen", "perf", "train"]
  }
}

locals {
  certificate_arn             = contains(local.wke.other, local.environment) ? local.account_layer.acm.wke[local.environment].certificate_arn : local.account_layer.acm.account.certificate_arn
  cloud_front_certificate_arn = contains(local.wke.other, local.environment) ? local.account_layer.acm.wke[local.environment].cloud_front_certificate_arn : local.account_layer.acm.account.cloud_front_certificate_arn
  enable_public_db            = local.is_dev
  is_dev                      = var.environment_type == "dev"

  use_auto_scaling  = local.use_prod_sizing
  use_ip_allow_list = local.environment != "prod"

  dns_names = contains(concat(local.wke.account, local.wke.other), local.environment) ? {
    cms_admin     = "cms.${local.account_layer.dns.wke_dns_names[local.environment]}"
    front_end     = "${local.account_layer.dns.wke_dns_names[local.environment]}"
    front_end_lb  = "lb.${local.account_layer.dns.wke_dns_names[local.environment]}"
    feedback_api  = "feedback-api.${local.account_layer.dns.wke_dns_names[local.environment]}"
    private_api   = "private-api.${local.account_layer.dns.wke_dns_names[local.environment]}"
    public_api    = "api.${local.account_layer.dns.wke_dns_names[local.environment]}"
    public_api_lb = "api-lb.${local.account_layer.dns.wke_dns_names[local.environment]}"
    } : {
    cms_admin     = "${local.environment}-cms.${local.account_layer.dns.account.dns_name}"
    front_end     = "${local.environment}.${local.account_layer.dns.account.dns_name}"
    front_end_lb  = "${local.environment}-lb.${local.account_layer.dns.account.dns_name}"
    feedback_api  = "${local.environment}-feedback-api.${local.account_layer.dns.account.dns_name}"
    private_api   = "${local.environment}-private-api.${local.account_layer.dns.account.dns_name}"
    public_api    = "${local.environment}-api.${local.account_layer.dns.account.dns_name}"
    public_api_lb = "${local.environment}-api-lb.${local.account_layer.dns.account.dns_name}"
  }
}
