module "cloudfront_legacy_dashboard_redirect" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "4.1.0"

  create_distribution = !contains(["pen", "staging", "perf"], local.environment)

  aliases             = [local.dns_names.legacy_dashboard]
  comment             = "${local.prefix}-legacy-dashboard-redirect"
  enabled             = true
  wait_for_deployment = true

  web_acl_id = aws_wafv2_web_acl.legacy_dashboard_redirect.arn

  origin = {
    front_end = {
      domain_name = "${local.dns_names.front_end}"

      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63" # CORS-with-preflight-and-SecurityHeadersPolicy
    target_origin_id           = "front_end"
    use_forwarded_values       = false
    viewer_protocol_policy     = "redirect-to-https"
    function_association = {
      viewer-request = {
        function_arn = aws_cloudfront_function.legacy_dashboard_redirect_viewer_request.arn
      }
    }
  }

  logging_config = {
    bucket          = data.aws_s3_bucket.cloud_front_logs_eu_west_2.bucket_domain_name
    enabled         = true
    include_cookies = false
    prefix          = "${local.prefix}-legacy-dashboard-redirect"
  }

  viewer_certificate = {
    acm_certificate_arn      = local.cloud_front_legacy_dashboard_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_function" "legacy_dashboard_redirect_viewer_request" {
  name    = "${local.prefix}-legacy-dashboard-redirect-viewer-request"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("../../src/legacy-dashboard-redirect-viewer-request/index.js")
}

resource "aws_cloudwatch_log_group" "cloud_front_function_legacy_dashboard_redirect_viewer_request" {
  name              = "/aws/cloudfront/function/${aws_cloudfront_function.legacy_dashboard_redirect_viewer_request.name}"
  provider          = aws.us_east_1
  retention_in_days = local.default_log_retention_in_days
}
