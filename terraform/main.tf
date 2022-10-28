terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      Version = "~>4.16"
    }
  }

  required_version = ">=1.2.0"

}

provider "aws" {
  region  = "eu-west-2"
}

backend "s3" {
    bucket = "ukhsa-dashboard-terra-backend"
    key    = "wl-backend-s3"
    region = "eu-west-2"
}

