resource "aws_shield_application_layer_automatic_response" "cloudfront_frontend" {
  count        = local.is_prod ? 1 : 0
  resource_arn = module.cloudfront_front_end.cloudfront_distribution_arn
  action       = "BLOCK"
}

resource "aws_shield_application_layer_automatic_response" "cloudfront_public_api" {
  count        = local.is_prod ? 1 : 0
  resource_arn = module.cloudfront_public_api.cloudfront_distribution_arn
  action       = "BLOCK"
}
