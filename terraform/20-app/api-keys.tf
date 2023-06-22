resource "random_password" "cms_api_key" {
  length      = 20
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  special     = false
}

resource "random_password" "api_secret_key" {
  length      = 50
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  special     = true
}
