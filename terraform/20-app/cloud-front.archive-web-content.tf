module "cloudfront_archive_web_content" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.1"

  aliases                      = [local.dns_names.archive]
  comment                      = "${local.prefix}-archive-web-content"
  create_origin_access_control = true
  default_root_object          = "index.html"
  enabled                      = true
  wait_for_deployment          = true
  web_acl_id                   = aws_wafv2_web_acl.archive_web_content.arn

  custom_error_response = [
    {
      error_code         = 403
      response_code      = 404
      response_page_path = "/errors/404.html"
    },
    {
      error_code         = 404
      response_code      = 404
      response_page_path = "/errors/404.html"
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
  }

  viewer_certificate = {
    acm_certificate_arn      = local.cloud_front_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
