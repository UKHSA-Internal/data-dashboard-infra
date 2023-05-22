locals {
  region      = "eu-west-2"
  project     = "uhd"
  environment = terraform.workspace
  prefix      = "${local.project}-${local.environment}"
}

locals {
  is_dev = var.environment_type == "dev"

  enable_public_db = local.is_dev
}
