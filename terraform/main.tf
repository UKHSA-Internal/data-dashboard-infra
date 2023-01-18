terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>4.16"
    }
  }

  backend "s3" {
    bucket = "wp-test-terraform-backend"
    key    = "wp-test-backend-s3"
    region = "eu-west-2"
  }

  required_version = ">=1.2.0"

}

provider "aws" {
  region  = "eu-west-2"
}



