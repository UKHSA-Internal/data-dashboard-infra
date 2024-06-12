locals {
  fifteen_minutes_in_seconds = 900
}

module "cloudfront_front_end" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.0"

  comment             = "${local.prefix}-front-end"
  enabled             = true
  wait_for_deployment = true
  aliases             = [local.dns_names.front_end]

  web_acl_id = aws_wafv2_web_acl.front_end.arn

  origin = {
    alb = {
      domain_name = local.dns_names.front_end_lb

      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }

      origin_shield = {
        enabled              = true
        origin_shield_region = local.region
      }

      custom_header = [
        {
          name  = "x-cdn-auth"
          value = jsonencode(aws_secretsmanager_secret_version.cdn_front_end_secure_header_value.secret_string)
        }
      ]
    }
  }

  viewer_certificate = {
    acm_certificate_arn      = local.cloud_front_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  default_cache_behavior = {
    allowed_methods          = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cache_policy_id          = aws_cloudfront_cache_policy.front_end.id
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    origin_request_policy_id = aws_cloudfront_origin_request_policy.front_end.id
    response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63" # CORS-with-preflight-and-SecurityHeadersPolicy
    target_origin_id         = "alb"
    use_forwarded_values     = false
    viewer_protocol_policy   = "redirect-to-https"
  }

  ordered_cache_behavior = [
    # Behaviour to bypass cloudfront for health check
    {
      path_pattern               = "api/health"
      allowed_methods            = ["GET", "HEAD", "OPTIONS"]
      cache_policy_name          = "Managed-CachingDisabled"
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end.id
      response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"
      target_origin_id           = "alb"
      use_forwarded_values       = false
      viewer_protocol_policy     = "redirect-to-https"
      query_string               = false
    },
    # Behaviour to bypass CDN for the dynamic alert pages
    {
      path_pattern               = "/weather-health-alerts"
      allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cache_policy_id            = aws_cloudfront_cache_policy.front_end_bypass_cdn.id
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end.id
      response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"
      target_origin_id           = "alb"
      use_forwarded_values       = false
      viewer_protocol_policy     = "redirect-to-https"
    },
    {
      path_pattern               = "/weather-health-alerts/*"
      allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cache_policy_id            = aws_cloudfront_cache_policy.front_end_bypass_cdn.id
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end.id
      response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"
      target_origin_id           = "alb"
      use_forwarded_values       = false
      viewer_protocol_policy     = "redirect-to-https"
    },
  ]

  custom_error_response = [
    {
      error_code            = 404
      error_caching_min_ttl = local.five_minutes_in_seconds
    }
  ]

  logging_config = {
    bucket          = data.aws_s3_bucket.cloud_front_logs_eu_west_2.bucket_domain_name
    enabled         = true
    include_cookies = false
    prefix          = "${local.prefix}-front-end"
  }
}

################################################################################
# Request policies
################################################################################

resource "aws_cloudfront_origin_request_policy" "front_end" {
  name = "${local.prefix}-front-end"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "allViewer"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

################################################################################
# Cache policies
################################################################################

resource "aws_cloudfront_cache_policy" "front_end" {
  name = "${local.prefix}-front-end"

  min_ttl     = local.use_prod_sizing ? local.thirty_days_in_seconds : local.fifteen_minutes_in_seconds
  max_ttl     = local.use_prod_sizing ? local.thirty_days_in_seconds : local.fifteen_minutes_in_seconds
  default_ttl = local.use_prod_sizing ? local.thirty_days_in_seconds : local.fifteen_minutes_in_seconds

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = [
          "_rsc",
          "areaName",
          "areaType",
          "page",
          "search",
        ]
      }
    }
  }
}

resource "aws_cloudfront_cache_policy" "front_end_bypass_cdn" {
  name = "${local.prefix}-front-end-bypass-cdn"

  min_ttl     = 0
  max_ttl     = 0
  default_ttl = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}
