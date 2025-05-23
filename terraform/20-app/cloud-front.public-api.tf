locals {
  one_day_in_seconds = 86400
}

module "cloudfront_public_api" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.0"

  comment             = "${local.prefix}-public-api"
  enabled             = true
  wait_for_deployment = true
  aliases             = [local.dns_names.public_api]

  web_acl_id = aws_wafv2_web_acl.public_api.arn

  origin = {
    alb = {
      domain_name = local.dns_names.public_api_lb

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
          value = jsonencode(aws_secretsmanager_secret_version.cdn_public_api_secure_header_value.secret_string)
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
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id = (
      local.auth_enabled ?
      local.managed_caching_disabled_policy_id :
      aws_cloudfront_cache_policy.public_api.id
    )
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    origin_request_policy_id = aws_cloudfront_origin_request_policy.public_api.id
    response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63" # CORS-with-preflight-and-SecurityHeadersPolicy
    target_origin_id         = "alb"
    use_forwarded_values     = false
    viewer_protocol_policy   = "redirect-to-https"
    function_association = {
      viewer-request = {
        function_arn = local.add_password_protection ? module.cloudfront_password_protection_public_api.arn : aws_cloudfront_function.public_api_viewer_request.arn
      }
    }
  }

  ordered_cache_behavior = [
    # Behaviour to bypass cloudfront for health check
    {
      path_pattern               = ".well-known/health-check/"
      allowed_methods            = ["GET", "HEAD", "OPTIONS"]
      cache_policy_name          = "Managed-CachingDisabled"
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.public_api_health_check.id
      response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"
      target_origin_id           = "alb"
      use_forwarded_values       = false
      viewer_protocol_policy     = "redirect-to-https"
      query_string               = false
    }
  ]

  custom_error_response = [
    {
      count                 = 0
      error_code            = 404
      error_caching_min_ttl = local.five_minutes_in_seconds
    }
  ]

  logging_config = {
    bucket          = data.aws_s3_bucket.cloud_front_logs_eu_west_2.bucket_domain_name
    enabled         = true
    include_cookies = false
    prefix          = "${local.prefix}-public-api"
  }
}

################################################################################
# Request policies
################################################################################

resource "aws_cloudfront_origin_request_policy" "public_api" {
  name = "${local.prefix}-public-api"

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

resource "aws_cloudfront_origin_request_policy" "public_api_health_check" {
  name = "${local.prefix}-public-api-health-check"

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

################################################################################
# Cache policies
################################################################################

resource "aws_cloudfront_cache_policy" "public_api" {
  name = "${local.prefix}-public-api"

  min_ttl     = local.use_prod_sizing ? local.thirty_days_in_seconds : local.one_day_in_seconds
  max_ttl     = local.use_prod_sizing ? local.thirty_days_in_seconds : local.one_day_in_seconds
  default_ttl = local.use_prod_sizing ? local.thirty_days_in_seconds : local.one_day_in_seconds

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["accept"]
      }
    }
    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = [
          "age",
          "date",
          "epiweek",
          "page",
          "page_size",
          "sex",
          "stratum",
          "year",
        ]
      }
    }
  }
}

resource "aws_cloudfront_cache_policy" "public_api_health_check" {
  name = "${local.prefix}-public-api-health-check"

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

################################################################################
# Viewer functions
################################################################################

resource "aws_cloudfront_function" "public_api_viewer_request" {
  name    = "${local.prefix}-public-api-viewer-request"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("../../src/public-api-cloud-front-viewer-request/index.js")
}

resource "aws_cloudwatch_log_group" "cloud_front_function_public_api_viewer_request" {
  name              = "/aws/cloudfront/function/${aws_cloudfront_function.public_api_viewer_request.name}"
  provider          = aws.us_east_1
  retention_in_days = local.default_log_retention_in_days
}

module "cloudfront_password_protection_public_api" {
  source = "../modules/cloud-front-basic-password-protection"
  create = local.add_password_protection
  name   = "${local.prefix}-public-api-password-protection"
}
