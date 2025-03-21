data "terraform_remote_state" "dev_account" {
  backend = "s3"

  workspace = "dev"

  config = {
    region         = "eu-west-2"
    bucket         = "uhd-terraform-states"
    dynamodb_table = "terraform-state-lock"
    key            = "account/state.tfstate"
  }
}

data "terraform_remote_state" "auth_dev_account" {
  backend = "s3"

  workspace = "auth-dev"

  config = {
    region         = "eu-west-2"
    bucket         = "uhd-terraform-states"
    dynamodb_table = "terraform-state-lock"
    key            = "account/state.tfstate"
  }
}

data "terraform_remote_state" "test_account" {
  backend = "s3"

  workspace = "test"

  config = {
    region         = "eu-west-2"
    bucket         = "uhd-terraform-states"
    dynamodb_table = "terraform-state-lock"
    key            = "account/state.tfstate"
  }
}

data "terraform_remote_state" "auth_test_account" {
  backend = "s3"

  workspace = "auth-test"

  config = {
    region         = "eu-west-2"
    bucket         = "uhd-terraform-states"
    dynamodb_table = "terraform-state-lock"
    key            = "account/state.tfstate"
  }
}

data "terraform_remote_state" "uat_account" {
  backend = "s3"

  workspace = "uat"

  config = {
    region         = "eu-west-2"
    bucket         = "uhd-terraform-states"
    dynamodb_table = "terraform-state-lock"
    key            = "account/state.tfstate"
  }
}

data "terraform_remote_state" "auth_uat_account" {
  backend = "s3"

  workspace = "auth-uat"

  config = {
    region         = "eu-west-2"
    bucket         = "uhd-terraform-states"
    dynamodb_table = "terraform-state-lock"
    key            = "account/state.tfstate"
  }
}

locals {
  account_states = {
    dev       = data.terraform_remote_state.dev_account.outputs
    auth-dev  = data.terraform_remote_state.auth_dev_account.outputs
    test      = data.terraform_remote_state.test_account.outputs
    auth-test = data.terraform_remote_state.auth_test_account.outputs
    uat       = data.terraform_remote_state.uat_account.outputs
    auth-uat  = data.terraform_remote_state.auth_uat_account.outputs
  }
}
