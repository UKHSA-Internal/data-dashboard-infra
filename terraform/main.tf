terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>4.16"
    }
  }

  backend "s3" {
    bucket = var.aws_s3_tfbucket
    key    = var.aws_s3_tfbucket_key
    region = var.aws_region
  }

  required_version = ">=1.2.0"

}

provider "aws" {
  region  = var.aws_region
}



