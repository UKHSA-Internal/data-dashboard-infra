locals {
  region      = "eu-west-2"
  project     = "uhd"
  environment = terraform.workspace
  prefix      = "${local.project}-${local.environment}"
}
