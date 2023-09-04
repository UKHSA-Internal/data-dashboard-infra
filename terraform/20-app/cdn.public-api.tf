module "cloudfront_public_api" {
  source                = "terraform-aws-modules/cloudfront/aws"
  version               = "3.2.0"

  comment               = "cdn distribution for UKHSA dashboard public api"
  enabled               = true
  wait_for_deployment   = true

  origin = {
      alb = {
          domain_name          = module.public_api_alb.lb_dns_name
          custom_origin_config = {
              http_port     = 80
              https_port    = 443
              origin_protocol_policy    = "http-only"
              origin_ssl_protocols      = ["TLSv1", "TLSv1.1", "TLSv1.2"]
          }

          custom_header = [
              {
                  name  = "Accept"
                  value = "text/html"
              },
              {
                name    = jsondecode(aws_secretsmanager_secret_version.cdn_public_api_secure_header_value.secret_string)["header"]
                value   = jsondecode(aws_secretsmanager_secret_version.cdn_public_api_secure_header_value.secret_string)["value"]
              }
          ]
      }
  }

  default_cache_behavior = {
      target_origin_id          = "alb"
      viewer_protocol_policy    = "allow-all"
      allowed_methods           = ["GET", "HEAD", "OPTIONS"]
      cached_methods            = ["GET", "HEAD"]
  }
}