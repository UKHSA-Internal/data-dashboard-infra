data "terraform_remote_state" "account" {
  backend = "s3"

  workspace = var.environment_type

  config = {
    region         = "eu-west-2"
    bucket         = "uhd-terraform-states"
    dynamodb_table = "terraform-state-lock"
    key            = "account/state.tfstate"
  }
}

locals {
  account_layer = data.terraform_remote_state.account.outputs
}
