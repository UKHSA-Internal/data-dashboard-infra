module "cloudfront_archive_web_content" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.0"

  aliases                      = [local.dns_names.archive]
  comment                      = "${local.prefix}-archive-web-content"
  create_origin_access_control = true
  default_root_object          = "index.html"
  enabled                      = true
  wait_for_deployment          = true
  web_acl_id                   = aws_wafv2_web_acl.archive_web_content.arn
  geo_restriction              = local.cloudfront_geo_restriction

  custom_error_response = [
    {
      error_caching_min_ttl = 900
      error_code            = 403
      response_code         = 404
      response_page_path    = "/errors/404.html"
    },
    {
      error_caching_min_ttl = 900
      error_code            = 404
      response_code         = 404
      response_page_path    = "/errors/404.html"
    }
  ]

  default_cache_behavior = {
    allowed_methods            = ["HEAD", "GET", "OPTIONS"]
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63" # CORS-with-preflight-and-SecurityHeadersPolicy
    target_origin_id           = "s3"
    use_forwarded_values       = false
    viewer_protocol_policy     = "redirect-to-https"
  }

  ordered_cache_behavior = [for ordered_cache_path in local.cloudfront_archive_web_content.ordered_cache_paths : {
    alowed_methods             = ["HEAD", "GET", "OPTIONS"]
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    path_pattern               = ordered_cache_path
    response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63" # CORS-with-preflight-and-SecurityHeadersPolicy
    target_origin_id           = "front_end"
    use_forwarded_values       = false
    viewer_protocol_policy     = "redirect-to-https"
  }]

  logging_config = {
    bucket          = data.aws_s3_bucket.cloud_front_logs_eu_west_2.bucket_domain_name
    enabled         = true
    include_cookies = false
    prefix          = "${local.prefix}-archive-web-content"
  }

  origin_access_control = {
    "${local.prefix}-archive-web-content" = {
      description      = "${local.prefix}-archive-web-content"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name           = module.s3_archive_web_content.s3_bucket_bucket_regional_domain_name
      origin_access_control = "${local.prefix}-archive-web-content"

      origin_shield = {
        enabled              = true
        origin_shield_region = local.region
      }
    }

    front_end = {
      domain_name = "${local.dns_names.front_end}"

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
    }
  }

  viewer_certificate = {
    acm_certificate_arn      = local.cloud_front_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

locals {
  cloudfront_archive_web_content = {
    ordered_cache_paths = [
      "/_next/*",
      "/assets/*",
      "/errors/*",
    ]
  }
}
