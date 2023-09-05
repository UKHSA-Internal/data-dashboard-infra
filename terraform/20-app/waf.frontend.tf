resource "aws_wafv2_web_acl" "front_end" {
    name        = "${local.prefix}-front-end"
    description = "Web ACL for front-end application"
    scope       = "REGIONAL"

    default_action {
        block {}
    }

    rule {
        name        = "ip-allow-list"
        priority    = 1

        action {
            allow {}
        }

        statement {
            ip_set_reference_statement {
                arn = aws_wafv2_ip_set.ip_allow_list.arn
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "AllowListIP"
            sampled_requests_enabled   = true
        }
    }

    # dynamic "rule" {
    #     for_each = local.waf_front_end.rules

    #     content {
    #         name        = rule.value.name
    #         priority    = rule.value.priority

    #         override_action {
    #             none {}
    #         }

    #         statement {
    #             managed_rule_group_statement {
    #                 name        = rule.value.name
    #                 vendor_name = "AWS"
    #             }
    #         }

    #         visibility_config {
    #             metric_name                 = rule.value.name
    #             cloudwatch_metrics_enabled  = true
    #             sampled_requests_enabled    = true
    #         }
    #     }
    # }

    visibility_config {
        metric_name                 = "${local.prefix}-front-end"
        cloudwatch_metrics_enabled  = true
        sampled_requests_enabled    = true 
    }
}

resource "aws_wafv2_ip_set" "ip_allow_list" {
    name               = "ip-allow-list"
    scope              = "REGIONAL"
    ip_address_version = "IPV4"
    addresses          = concat(
        local.ip_allow_list.engineers,
        local.ip_allow_list.project_team,
        local.ip_allow_list.other_stakeholders,
        local.ip_allow_list.user_testing_participants
    )
}

resource "aws_wafv2_web_acl_association" "front_end" {
    resource_arn    = module.front_end_alb.lb_arn
    web_acl_arn     = aws_wafv2_web_acl.front_end.arn
}

locals {
    waf_front_end = {
        rules = [
            {
                priority    = 2
                name        = "AWSManagedRulesCommonRuleSet"
            },
            {
                priority    = 3
                name        = "AWSManagedRulesKnownBadInputsRuleSet"
            },
            {
                priority    = 4
                name        = "AWSManagedRulesAmazonIpReputationList"
            },
            {
                priority    = 5
                name        = "AWSManagedRulesLinuxRuleSet"
            },
            {
                priority    = 6
                name        = "AWSManagedRulesUnixRuleSet"
            }
        ]
    }
}
