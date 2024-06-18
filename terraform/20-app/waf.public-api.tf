resource "aws_wafv2_web_acl" "public_api" {
  name        = "${local.prefix}-public-api"
  description = "Web ACL for public api application"
  scope       = "CLOUDFRONT"
  provider    = aws.us_east_1

  default_action {
    dynamic "block" {
      for_each = local.use_ip_allow_list ? [""] : []
      content {
      }
    }
    dynamic "allow" {
      for_each = local.use_ip_allow_list ? [] : [""]
      content {
      }
    }
  }

  dynamic "rule" {
    for_each = local.waf_public_api.rules

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
    metric_name                = "${local.prefix}-public-api"
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
  }

  rule {
    name     = "ip-allow-list"
    priority = 6

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

  rule {
    name     = "rate-limiting"
    priority = 7

    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
}

locals {
  waf_public_api = {
    rules = [
      {
        priority = 1
        name     = "AWSManagedRulesCommonRuleSet"
      },
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

resource "aws_wafv2_web_acl_logging_configuration" "public_api" {
  log_destination_configs = [data.aws_s3_bucket.halo_waf_logs_us_east_1.arn]
  provider                = aws.us_east_1
  resource_arn            = aws_wafv2_web_acl.public_api.arn
}
