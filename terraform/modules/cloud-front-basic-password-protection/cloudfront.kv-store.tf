resource "aws_cloudfront_key_value_store" "password_protection" {
  count = var.create ? 1 : 0
  name  = var.name
}
