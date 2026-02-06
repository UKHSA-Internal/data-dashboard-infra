locals {
  eight_hours_in_seconds              = 28800
  managed_caching_disabled_policy_id  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

module "cloudfront_front_end" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.2.0"

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
    allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cache_policy_id            = (
        local.is_front_end_bypassing_cdn ?
        local.managed_caching_disabled_policy_id :
        aws_cloudfront_cache_policy.front_end.id
      )
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.front_end.id
    target_origin_id           = "alb"
    use_forwarded_values       = false
    viewer_protocol_policy     = "redirect-to-https"
    function_association       = local.add_password_protection ? {
      viewer-request = {
        function_arn = module.cloudfront_password_protection_frontend.arn
      }
    } : {}
  }

  ordered_cache_behavior = flatten(concat([
    # Behaviour to bypass cloudfront for health check
    {
      path_pattern               = "api/health"
      allowed_methods            = ["GET", "HEAD", "OPTIONS"]
      cache_policy_name          = "Managed-CachingDisabled"
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end.id
      response_headers_policy_id = aws_cloudfront_response_headers_policy.front_end.id
      target_origin_id           = "alb"
      use_forwarded_values       = false
      viewer_protocol_policy     = "redirect-to-https"
      query_string               = false
    },
    # Behaviour to enable cookie forwarding for auth endpoints
    local.auth_enabled ? [
      {
        path_pattern               = "/api/auth/*"
        allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
        cache_policy_id            = local.managed_caching_disabled_policy_id
        cached_methods             = ["GET", "HEAD"]
        compress                   = true
        origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end_auth.id
        response_headers_policy_id = aws_cloudfront_response_headers_policy.front_end.id
        target_origin_id           = "alb"
        use_forwarded_values       = false
        viewer_protocol_policy     = "redirect-to-https"
      }
    ] : [],
    # Behaviour to bypass CDN for the dynamic alert pages
    {
      path_pattern               = "/"
      allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cache_policy_id            = (
        local.is_front_end_bypassing_cdn ?
        local.managed_caching_disabled_policy_id :
        aws_cloudfront_cache_policy.front_end_low_ttl.id
      )
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end.id
      response_headers_policy_id = aws_cloudfront_response_headers_policy.front_end.id
      target_origin_id           = "alb"
      use_forwarded_values       = false
      viewer_protocol_policy     = "redirect-to-https"
    },
    {
      path_pattern               = "/weather-health-alerts"
      allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cache_policy_id            = (
        local.is_front_end_bypassing_cdn ?
        local.managed_caching_disabled_policy_id :
        aws_cloudfront_cache_policy.front_end_low_ttl.id
      )
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end.id
      response_headers_policy_id = aws_cloudfront_response_headers_policy.front_end.id
      target_origin_id           = "alb"
      use_forwarded_values       = false
      viewer_protocol_policy     = "redirect-to-https"
    },
    {
      path_pattern               = "/weather-health-alerts/*"
      allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cache_policy_id            = (
        local.is_front_end_bypassing_cdn ?
        local.managed_caching_disabled_policy_id :
        aws_cloudfront_cache_policy.front_end_low_ttl.id
      )
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end.id
      response_headers_policy_id = aws_cloudfront_response_headers_policy.front_end.id
      target_origin_id           = "alb"
      use_forwarded_values       = false
      viewer_protocol_policy     = "redirect-to-https"
    },
    {
      path_pattern               = "/api/proxy/alerts/*"
      allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cache_policy_name          = "Managed-CachingDisabled"
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.front_end.id
      response_headers_policy_id = aws_cloudfront_response_headers_policy.front_end.id
      target_origin_id           = "alb"
      use_forwarded_values       = false
      viewer_protocol_policy     = "redirect-to-https"
    },
  ]))

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
    cookie_behavior = "whitelist"
    cookies {
      items = flatten(concat(["UKHSAConsentGDPR", local.auth_enabled ? [
        "__Secure-authjs.callback-url",  # Stores the redirect destination after authentication
        "__Secure-authjs.csrf-token",  # CSRF token required for authentication flows
        "__Secure-authjs.session-token",  # Main session token
        "__Secure-authjs.session-token.0",  # Split session token (if size exceeds 4KB)
        "__Secure-authjs.session-token.1",  # Additional split session token
        "__Secure-authjs.session-token.2",  # Additional split session token
        "__Secure-authjs.session-token.3",  # Additional split session token
        "__Secure-authjs.session-token.4",  # Additional split session token (safety margin)
      ] : []]))
    }
  }
  headers_config {
    header_behavior = "allViewer"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_origin_request_policy" "front_end_auth" {
  name = "${local.prefix}-front-end-auth"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Accept",
        "Content-Type",
        "Set-Cookie",
      ]
    }
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

  min_ttl     = local.use_prod_sizing ? local.thirty_days_in_seconds : local.eight_hours_in_seconds
  max_ttl     = local.use_prod_sizing ? local.thirty_days_in_seconds : local.eight_hours_in_seconds
  default_ttl = local.use_prod_sizing ? local.thirty_days_in_seconds : local.eight_hours_in_seconds

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "whitelist"
      cookies {
        items = ["UKHSAConsentGDPR"]
      }
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
          "geography_type",
        ]
      }
    }
  }
}

resource "aws_cloudfront_cache_policy" "front_end_low_ttl" {
  name = "${local.prefix}-front-end-low-ttl"

  min_ttl     = local.five_minutes_in_seconds
  max_ttl     = local.five_minutes_in_seconds
  default_ttl = local.five_minutes_in_seconds

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "whitelist"
      cookies {
        items = ["UKHSAConsentGDPR"]
      }
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
          "type",
          "v",
          "fid",
          "geography_type",
        ]
      }
    }
  }
}


################################################################################
# Request viewer
################################################################################

module "cloudfront_password_protection_frontend" {
  source = "../modules/cloud-front-basic-password-protection"
  create = local.add_password_protection
  name   = "${local.prefix}-front-end-password-protection"
}


################################################################################
# Response policies
################################################################################
resource "aws_cloudfront_response_headers_policy" "front_end" {
  name = "${local.prefix}-front-end"

  cors_config {
    access_control_allow_credentials = false
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_expose_headers {
      items = ["*"]
    }
    access_control_allow_origins {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    }
    origin_override = false
  }

  security_headers_config {
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = false
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      override                   = false
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    xss_protection {
      protection = true
      mode_block = true
      override   = false
    }
  }
}
