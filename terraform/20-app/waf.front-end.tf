resource "aws_wafv2_web_acl" "front_end" {
  name        = "${local.prefix}-front-end"
  description = "Web ACL for front-end application"
  scope       = "CLOUDFRONT"
  provider    = aws.us_east_1

  default_action {
    block {}
  }

  rule {
    name     = "ip-allow-list"
    priority = 1

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
    for_each = local.waf_front_end.rules

    content {
      name     = rule.value.name
      priority = rule.value.priority

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
        metric_name                = rule.value.name
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    metric_name                = "${local.prefix}-front-end"
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
  }
}

locals {
  waf_front_end = {
    rules = [
      {
        priority = 2
        name     = "AWSManagedRulesCommonRuleSet"
      },
      {
        priority = 3
        name     = "AWSManagedRulesKnownBadInputsRuleSet"
      },
      {
        priority = 4
        name     = "AWSManagedRulesAmazonIpReputationList"
      },
      {
        priority = 5
        name     = "AWSManagedRulesLinuxRuleSet"
      },
      {
        priority = 6
        name     = "AWSManagedRulesUnixRuleSet"
      }
    ]
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "front_end" {
  log_destination_configs = [data.aws_s3_bucket.halo_waf_logs_us_east_1.arn]
  provider                = aws.us_east_1
  resource_arn            = aws_wafv2_web_acl.front_end.arn
}