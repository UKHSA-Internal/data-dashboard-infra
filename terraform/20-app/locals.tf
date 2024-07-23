locals {
  region      = "eu-west-2"
  project     = "uhd"
  environment = terraform.workspace
  prefix      = "${local.project}-${local.environment}"

  account_id                    = var.assume_account_id
  default_log_retention_in_days = 30
  alb_security_policy           = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  use_prod_sizing         = contains(["perf", "uat", "prod"], local.environment)
  add_password_protection = local.environment == "staging"

  wke = {
    account = ["dev", "test", "uat", "prod"]
    other   = ["pen", "perf", "train"]
  }
}

locals {
  certificate_arn                              = contains(local.wke.other, local.environment) ? local.account_layer.acm.wke[local.environment].certificate_arn : local.account_layer.acm.account.certificate_arn
  cloud_front_certificate_arn                  = contains(local.wke.other, local.environment) ? local.account_layer.acm.wke[local.environment].cloud_front_certificate_arn : local.account_layer.acm.account.cloud_front_certificate_arn
  cloud_front_legacy_dashboard_certificate_arn = local.account_layer.acm.legacy.cloud_front_certificate_arn
  enable_public_db                             = local.is_dev
  is_dev                                       = var.environment_type == "dev"
  is_prod                                      = local.environment == "prod"

  use_ip_allow_list = local.environment != "prod"

  scheduled_scaling_policies_for_non_essential_envs = {
    start_of_working_day_scale_out = {
      min_capacity = local.use_prod_sizing ? 3 : 1
      max_capacity = local.use_prod_sizing ? 3 : 1
      schedule     = "cron(0 07 ? * MON-FRI *)" # Run every weekday at 7am
    }
    end_of_working_day_scale_in = {
      min_capacity = 0
      max_capacity = 0
      schedule     = "cron(0 20 ? * MON-FRI *)" # Run every weekday at 8pm
    }
  }

  ship_cloud_watch_logs_to_splunk = true

  dns_names = contains(concat(local.wke.account, local.wke.other), local.environment) ? {
    archive          = "archive.${local.account_layer.dns.wke_dns_names[local.environment]}"
    cms_admin        = "cms.${local.account_layer.dns.wke_dns_names[local.environment]}"
    feedback_api     = "feedback-api.${local.account_layer.dns.wke_dns_names[local.environment]}"
    front_end        = local.account_layer.dns.wke_dns_names[local.environment]
    front_end_lb     = "lb.${local.account_layer.dns.wke_dns_names[local.environment]}"
    legacy_dashboard = local.account_layer.dns.legacy.dns_name
    private_api      = "private-api.${local.account_layer.dns.wke_dns_names[local.environment]}"
    public_api       = "api.${local.account_layer.dns.wke_dns_names[local.environment]}"
    public_api_lb    = "api-lb.${local.account_layer.dns.wke_dns_names[local.environment]}"
    feature_flags    = "feature-flags.${local.account_layer.dns.wke_dns_names[local.environment]}"
    } : {
    archive          = "${local.environment}-archive.${local.account_layer.dns.account.dns_name}"
    cms_admin        = "${local.environment}-cms.${local.account_layer.dns.account.dns_name}"
    feedback_api     = "${local.environment}-feedback-api.${local.account_layer.dns.account.dns_name}"
    front_end        = "${local.environment}.${local.account_layer.dns.account.dns_name}"
    front_end_lb     = "${local.environment}-lb.${local.account_layer.dns.account.dns_name}"
    legacy_dashboard = "${local.environment}.${local.account_layer.dns.legacy.dns_name}"
    private_api      = "${local.environment}-private-api.${local.account_layer.dns.account.dns_name}"
    public_api       = "${local.environment}-api.${local.account_layer.dns.account.dns_name}"
    public_api_lb    = "${local.environment}-api-lb.${local.account_layer.dns.account.dns_name}"
    feature_flags    = "${local.environment}-feature-flags.${local.account_layer.dns.account.dns_name}"
  }

  thirty_days_in_seconds  = 2592000
  five_minutes_in_seconds = 300

  main_db_aurora_password_secret_arn = module.aurora_db_app.cluster_master_user_secret[0]["secret_arn"]
}
