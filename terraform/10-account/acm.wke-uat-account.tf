module "acm_wke_train" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  create_certificate = local.account == "uat"

  domain_name = local.wke_dns_names.train
  zone_id     = local.account == "uat" ? module.route_53_zone_wke_test_account.route53_zone_zone_id[local.wke_dns_names.train] : ""

  subject_alternative_names = [
    "*.${local.wke_dns_names.train}"
  ]

  wait_for_validation = true
}
