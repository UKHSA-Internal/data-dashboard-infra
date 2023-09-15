module "cloudfront_front_end" {
    source                = "terraform-aws-modules/cloudfront/aws"
    version               = "3.2.1"

    comment               = "${local.prefix}-front-end"
    enabled               = true
    wait_for_deployment   = true
    aliases               = [local.dns_names.front_end]

    web_acl_id            = aws_wafv2_web_acl.front_end.arn
  
    origin = {
        alb = {
            domain_name            = local.dns_names.front_end_lb
            custom_origin_config   = {
                http_port     = 80
                https_port    = 443
                origin_protocol_policy = "https-only"
                origin_ssl_protocols   = ["TLSv1.2"]
            }

            custom_header = [
                {
                    name    = "x-cdn-auth"
                    value   = jsonencode(aws_secretsmanager_secret_version.cdn_front_end_secure_header_value.secret_string)
                }
            ]
        }
    }

    viewer_certificate = {
        acm_certificate_arn = local.cloud_front_certificate_arn
        ssl_support_method  = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }

    default_cache_behavior = {
        target_origin_id          = "alb"
        viewer_protocol_policy    = "allow-all"
        allowed_methods           = ["GET", "HEAD", "OPTIONS"]
        cached_methods            = ["GET", "HEAD"]
        min_ttl                   = local.environment == "prod" ? 2592000 : 900
        default_ttl               = local.environment == "prod" ? 2592000 : 900
        max_ttl                   = local.environment == "prod" ? 2592000 : 900
    }
}