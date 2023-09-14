resource "aws_wafv2_web_acl" "public_api" {
    name        = "${local.prefix}-public-api"
    description = "Web ACL for public api application"
    scope       = "CLOUDFRONT"
    provider    = aws.us_east_1

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

    dynamic "rule" {
        for_each = local.waf_public_api.rules

        content {
            name        = rule.value.name
            priority    = rule.value.priority

            override_action {
                count {}
            }

            statement {
                managed_rule_group_statement {
                    name        = rule.value.name
                    vendor_name = "AWS"
                }
            }

            visibility_config {
                metric_name                 = rule.value.name
                cloudwatch_metrics_enabled  = true
                sampled_requests_enabled    = true
            }
        }
    }

    visibility_config {
        metric_name                 = "${local.prefix}-public-api"
        cloudwatch_metrics_enabled  = true
        sampled_requests_enabled    = true
    }
}

locals {
    waf_public_api = {
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
