provider "aws" {
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${var.assume_account_id}:role/${var.assume_role_name}"
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.assume_account_id}:role/${var.assume_role_name}"
  }

  default_tags {
    tags = {
      project_name = local.project
      env          = terraform.workspace
    }
  }
}

terraform {
  backend "s3" {
    region         = "eu-west-2"
    bucket         = "uhd-terraform-states"
    dynamodb_table = "terraform-state-lock"
    key            = "app/state.tfstate"
  }
}

