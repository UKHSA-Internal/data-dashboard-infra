module "acm_cloud_front_wke_train" {
    source  = "terraform-aws-modules/acm/aws"
    version = "6.0.0"

    create_certificate = local.account == "uat"

    domain_name = local.wke_dns_names.train
    zone_id     = local.account == "uat" ? module.route_53_zone_wke_uat_account.route53_zone_zone_id[local.wke_dns_names.train] : ""

    providers = {
        aws = aws.us_east_1
    }

    subject_alternative_names = [
        "*.${local.wke_dns_names.train}"
    ]

    wait_for_validation = true
}
