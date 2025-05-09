resource "aws_wafv2_web_acl" "cms_admin" {
  name        = "${local.prefix}-cms-admin"
  description = "Web ACL for CMS application"
  scope       = "REGIONAL"

  lifecycle {
    create_before_destroy = true
  }

  default_action {
    dynamic "block" {
      for_each = [""]
      content {
      }
    }
    dynamic "allow" {
      for_each = []
      content {
      }
    }
  }

  rule {
    name     = "ip-allowlist"
    priority = 0

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ip_allow_list_regional.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPAllowListRule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            allow {}
          }
          name = "SizeRestrictions_BODY"
        }
      }
    }

    visibility_config {
      metric_name                = "AWSManagedRulesCommonRuleSet"
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limiting"
    priority = 6

    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = local.waf_cms_admin.rules

    content {
      name     = rule.value.name
      priority = rule.value.priority

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
        metric_name                = rule.value.name
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    metric_name                = "${local.prefix}-cms"
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "cms_admin" {
  resource_arn = module.cms_admin_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.cms_admin.arn
}

locals {
  waf_cms_admin = {
    rules = [
      {
        priority = 2
        name     = "AWSManagedRulesKnownBadInputsRuleSet"
      },
      {
        priority = 3
        name     = "AWSManagedRulesAmazonIpReputationList"
      },
      {
        priority = 4
        name     = "AWSManagedRulesLinuxRuleSet"
      },
      {
        priority = 5
        name     = "AWSManagedRulesUnixRuleSet"
      }
    ]
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "cms_admin" {
  log_destination_configs = [data.aws_s3_bucket.halo_waf_logs_eu_west_2.arn]
  resource_arn            = aws_wafv2_web_acl.cms_admin.arn
}
