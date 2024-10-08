resource "random_password" "cms_admin_user_password" {
  length      = 10
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  special     = false
}

resource "random_password" "cdn_front_end_secure_header_value" {
  length      = 20
  min_numeric = 1
  min_upper   = 1
  special     = false
}

resource "random_password" "cdn_public_api_secure_header_value" {
  length      = 20
  min_numeric = 1
  min_upper   = 1
  special     = false
}
