module "acm_cloud_front_wke_pen" {
    source  = "terraform-aws-modules/acm/aws"
    version = "5.2.0"

    create_certificate = local.account == "test"

    domain_name = local.wke_dns_names.pen
    zone_id     = local.account == "test" ? module.route_53_zone_wke_test_account.route53_zone_zone_id[local.wke_dns_names.pen] : ""

    providers = {
        aws = aws.us_east_1
    }

    subject_alternative_names = [
        "*.${local.wke_dns_names.pen}"
    ]

    validation_method   = "DNS"
    wait_for_validation = true
}

module "acm_cloud_front_wke_perf" {
    source  = "terraform-aws-modules/acm/aws"
    version = "5.2.0"

    create_certificate = local.account == "test"

    domain_name = local.wke_dns_names.perf
    zone_id     = local.account == "test" ? module.route_53_zone_wke_test_account.route53_zone_zone_id[local.wke_dns_names.perf] : ""

    providers = {
        aws = aws.us_east_1
    }

    subject_alternative_names = [
        "*.${local.wke_dns_names.perf}"
    ]

    validation_method   = "DNS"
    wait_for_validation = true
}
