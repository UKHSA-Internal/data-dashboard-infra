module "cloudfront_public_api" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.0"

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
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id            = aws_cloudfront_cache_policy.public_api.id
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.public_api.id
    response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63" # CORS-with-preflight-and-SecurityHeadersPolicy
    target_origin_id           = "alb"
    use_forwarded_values       = false
    viewer_protocol_policy     = "redirect-to-https"
  }

  logging_config = {
    bucket          = data.aws_s3_bucket.cloud_front_logs_eu_west_2.bucket_domain_name
    enabled         = true
    include_cookies = false
    prefix          = "${local.prefix}-public-api"
  }
}

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

resource "aws_cloudfront_cache_policy" "public_api" {
  name = "${local.prefix}-public-api"

  min_ttl     = local.environment == "prod" ? 2592000 : 900
  default_ttl = local.environment == "prod" ? 2592000 : 900
  max_ttl     = local.environment == "prod" ? 2592000 : 900

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

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
      query_string_behavior = "all"
    }
  }
}
