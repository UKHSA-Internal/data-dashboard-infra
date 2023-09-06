locals {
  region      = "eu-west-2"
  project     = "uhd"
  environment = terraform.workspace
  prefix      = "${local.project}-${local.environment}"
}

locals {
  is_dev = var.environment_type == "dev"

  enable_public_db = local.is_dev

  wke = {
    account = ["dev", "test", "uat", "prod"]
    other   = ["pen", "perf", "train"]
  }
}

locals {
  certificate_arn = contains(local.wke.other, local.environment) ? local.account_layer.acm.wke[local.environment].certificate_arn : local.account_layer.acm.account.certificate_arn
}
