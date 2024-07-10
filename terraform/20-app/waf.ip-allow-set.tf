resource "aws_wafv2_ip_set" "ip_allow_list" {
    name               = "${local.prefix}-ip-allow-list"
    scope              = "CLOUDFRONT"
    provider           = aws.us_east_1
    ip_address_version = "IPV4"
    addresses          = concat(
        local.complete_ip_allow_list,
        formatlist("%s/32", module.vpc.nat_public_ips)
    )
}
