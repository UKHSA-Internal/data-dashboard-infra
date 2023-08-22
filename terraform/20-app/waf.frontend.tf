resource "aws_wafv2_web_acl" "front_end" {
    name        = "${local.prefix}-front-end"
    description = "Web ACL for front-end application"
    scope       = "REGIONAL"

    default_action {
        allow {}
    }

    dynamic "rule" {
        for_each = local.waf_front_end.rules

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
        metric_name                 = "${local.prefix}-front-end"
        cloudwatch_metrics_enabled  = true
        sampled_requests_enabled    = true 
    }
}

resource "aws_wafv2_web_acl_association" "front_end" {
    resource_arn    = module.front_end_alb.lb_arn
    web_acl_arn     = aws_wafv2_web_acl.front_end.arn
}

locals {
    waf_front_end = {
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
