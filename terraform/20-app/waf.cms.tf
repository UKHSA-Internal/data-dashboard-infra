resource "aws_wafv2_web_acl" "cms_admin" {
    name        = "${local.prefix}-cms-admin"
    description = "Web ACL for CMS application"
    scope       = "REGIONAL"

    default_action {
        allow {}
    }

    dynamic "rule" {
        for_each = local.waf_cms_admin.rules

        content {
            name        = rule.value.name
            priority    = rule.value.priority

            override_action {
                none {}
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
        metric_name                 = "${local.prefix}-cms"
        cloudwatch_metrics_enabled  = true
        sampled_requests_enabled    = true
    }
}

resource "aws_wafv2_web_acl_association" "cms_admin" {
    resource_arn    = module.cms_admin_alb.lb_arn
    web_acl_arn     = aws_wafv2_web_acl.cms_admin.arn
}

locals {
    waf_cms_admin = {
        rules = [
            {
                priority    = 1
                name        = "AWSManagedRulesCommonRuleSet"
            },
            {
                priority    = 2
                name        = "AWSManagedRulesKnownBadInputsRuleSet"
            },
            {
                priority    = 3
                name        = "AWSManagedRulesAmazonIpReputationList"
            },
            {
                priority    = 4
                name        = "AWSManagedRulesLinuxRuleSet"
            },
            {
                priority    = 5
                name        = "AWSManagedRulesUnixRuleSet"
            }
        ]
    }
}
