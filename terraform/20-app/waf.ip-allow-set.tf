resource "aws_wafv2_ip_set" "ip_allow_list" {
    name               = "${local.prefix}-ip-allow-list"
    scope              = "CLOUDFRONT"
    provider           = aws.us_east_1
    ip_address_version = "IPV4"
    addresses          = concat(
        local.ip_allow_list.engineers,
        local.ip_allow_list.project_team,
        local.ip_allow_list.other_stakeholders,
        local.ip_allow_list.user_testing_participants
    )
}
